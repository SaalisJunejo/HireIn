import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import axios from "axios";

// ============================================================================
// HireIn MCP Server Bridge
// Exposes 9 Firebase v2 Cloud Functions as MCP tools for Google Antigravity.
//
// Architecture:
//   Google Antigravity (Gemini) ──stdio──> This MCP Server ──HTTP POST──> Firebase
//
// Each tool maps 1:1 to a deployed Firebase Cloud Function.
// The Firebase project is "hirein-4" deployed to us-central1.
// ============================================================================

const server = new Server(
  {
    name: "HireIn MCP Bridge",
    version: "2.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Firebase Cloud Run base URL component.
// For Firebase v2 functions on project "hirein-4", the URL pattern is:
//   https://<functionName>-<projectHash>-uc.a.run.app
// Set FIREBASE_FUNCTIONS_BASE_URL env var to override, or it uses the default.
const FIREBASE_URL_BASE = process.env.FIREBASE_FUNCTIONS_BASE_URL || "";
const FIREBASE_PROJECT_HASH = process.env.FIREBASE_PROJECT_HASH || "wsesv75pxa";
const FIREBASE_REGION = process.env.FIREBASE_REGION || "uc"; // us-central1 = "uc"

// Map MCP tool names -> actual Firebase function export names
// (some Firebase exports differ from the clean tool names)
const FUNCTION_NAME_MAP: Record<string, string> = {
  extractIntent: "extractIntent",
  discoverProviders: "discoverProviders",
  rankProviders: "rankProviders",
  calculatePricing: "calculatePricing",
  selectMatch: "selectMatch",
  lockBooking: "lockBooking",
  followUp: "sendFollowUp",         // Firebase export is "sendFollowUp"
  review: "updateReviewAndBadges",  // Firebase export is "updateReviewAndBadges"
  dispute: "handleDispute",         // Firebase export is "handleDispute"
};

// Tool definitions exposed to Antigravity
const FIREBASE_TOOLS = [
  {
    name: "extractIntent",
    description:
      "Agent 1 — Intent Extractor. Parses natural language input (Urdu, Roman Urdu, English) into structured service request fields: service type, location, time, urgency, confidence score, and detected language.",
    inputSchema: {
      type: "object" as const,
      properties: {
        userInput: {
          type: "string",
          description: "Raw natural language text from the user, e.g. 'Mujhe kal subah AC technician chahiye'",
        },
      },
      required: ["userInput"],
    },
  },
  {
    name: "discoverProviders",
    description:
      "Agent 2 — Provider Discovery. Searches Firestore for approved providers matching the service category within the given radius of the customer's coordinates. Returns providers with distanceKm calculated.",
    inputSchema: {
      type: "object" as const,
      properties: {
        category: { type: "string", description: "Service category, e.g. 'AC Technician'" },
        lat: { type: "number", description: "Customer latitude" },
        lng: { type: "number", description: "Customer longitude" },
        radiusKm: { type: "number", description: "Search radius in kilometers (default 15)" },
      },
      required: ["category", "lat", "lng", "radiusKm"],
    },
  },
  {
    name: "rankProviders",
    description:
      "Agent 3 — Ranking Engine. Scores and ranks discovered providers using weighted criteria: distance (40%), rating (30%), on-time score (20%), risk score (10%). Returns ranked list with score breakdowns and reasoning.",
    inputSchema: {
      type: "object" as const,
      properties: {
        providers: {
          type: "array",
          items: { type: "object" },
          description: "Array of provider objects from discoverProviders",
        },
        intent: {
          type: "object",
          description: "The structured intent object from extractIntent",
        },
      },
      required: ["providers", "intent"],
    },
  },
  {
    name: "calculatePricing",
    description:
      "Agent 4 — Pricing Engine. Calculates itemized pricing breakdown (base fee, travel fee, urgent surcharge, platform fee, total) in PKR for a specific provider and distance.",
    inputSchema: {
      type: "object" as const,
      properties: {
        providerId: { type: "string", description: "Provider ID" },
        service: { type: "string", description: "Service category" },
        distanceKm: { type: "number", description: "Distance to customer in km" },
        isUrgent: { type: "boolean", description: "Whether the request is urgent" },
      },
      required: ["providerId", "service", "distanceKm", "isUrgent"],
    },
  },
  {
    name: "selectMatch",
    description:
      "Agent 5 — Matchmaker. Selects the best provider from the ranked list considering pricing, and generates a human-readable reasoning summary for the customer.",
    inputSchema: {
      type: "object" as const,
      properties: {
        rankedProviders: {
          type: "array",
          items: { type: "object" },
          description: "Top 3 ranked providers from rankProviders",
        },
        pricing: {
          type: "object",
          description: "Pricing breakdown from calculatePricing",
        },
      },
      required: ["rankedProviders", "pricing"],
    },
  },
  {
    name: "lockBooking",
    description:
      "Agent 6 — Lock & Book. Simulates booking confirmation by writing a booking record to Firestore with status 'booked'. Generates a BK-XXXX booking ID.",
    inputSchema: {
      type: "object" as const,
      properties: {
        providerId: { type: "string", description: "Selected provider ID" },
        customerId: { type: "string", description: "Customer user ID" },
        timeSlot: { type: "string", description: "Scheduled time slot" },
        service: { type: "string", description: "Service category" },
        customerLat: { type: "number", description: "Customer latitude" },
        customerLng: { type: "number", description: "Customer longitude" },
        customerArea: { type: "string", description: "Customer area name" },
        pricingBreakdown: { type: "object", description: "Pricing details from calculatePricing" },
        isUrgent: { type: "boolean", description: "Whether urgent" },
      },
      required: ["providerId", "customerId", "timeSlot"],
    },
  },
  {
    name: "followUp",
    description:
      "Agent 7 — Follow-Up Automation. Sends simulated follow-up messages (reminder, en_route alert, completion prompt) for a booking.",
    inputSchema: {
      type: "object" as const,
      properties: {
        bookingId: { type: "string", description: "Booking ID from lockBooking" },
        type: {
          type: "string",
          description: "Follow-up type: 'reminder', 'en_route', or 'completion_prompt'",
        },
      },
      required: ["bookingId", "type"],
    },
  },
  {
    name: "review",
    description:
      "Agent 8 — Review & Badges. Processes a customer review, updates provider rating and badges in Firestore.",
    inputSchema: {
      type: "object" as const,
      properties: {
        bookingId: { type: "string", description: "Booking ID" },
        rating: { type: "number", description: "Rating 1-5" },
        feedback: { type: "string", description: "Customer feedback text" },
        providerId: { type: "string", description: "Provider ID to update" },
        customerBadges: {
          type: "array",
          items: { type: "string" },
          description: "Badge chips selected by customer",
        },
      },
      required: ["providerId", "rating"],
    },
  },
  {
    name: "dispute",
    description:
      "Agent 9 — Dispute Resolution. Automatically resolves customer disputes (overcharge, no-show, cancellation, poor quality) with refund calculations and provider penalties.",
    inputSchema: {
      type: "object" as const,
      properties: {
        bookingId: { type: "string", description: "Booking ID" },
        customerId: { type: "string", description: "Customer ID" },
        providerId: { type: "string", description: "Provider ID" },
        disputeType: {
          type: "string",
          description: "Type: 'no_show', 'overcharge', 'poor_quality', 'provider_cancelled', 'other'",
        },
        description: { type: "string", description: "Customer's description of the issue" },
      },
      required: ["bookingId", "disputeType", "description"],
    },
  },
];

// ─── Tool List Handler ───
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return { tools: FIREBASE_TOOLS };
});

// ─── Tool Execution Handler ───
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const toolName = request.params.name;
  const toolArgs = request.params.arguments;

  const tool = FIREBASE_TOOLS.find((t) => t.name === toolName);
  if (!tool) {
    throw new Error(`Unknown tool: ${toolName}`);
  }

  // Resolve the actual Firebase function name
  const firebaseFunctionName = FUNCTION_NAME_MAP[toolName] || toolName;

  // Construct Firebase v2 Cloud Run URL
  let url: string;
  if (FIREBASE_URL_BASE) {
    // If a full base URL is provided (e.g., for emulator or custom domain)
    url = `${FIREBASE_URL_BASE}/${firebaseFunctionName}`;
  } else {
    // Default Cloud Run URL pattern for Firebase v2 functions
    url = `https://${firebaseFunctionName.toLowerCase()}-${FIREBASE_PROJECT_HASH}-${FIREBASE_REGION}.a.run.app`;
  }

  const startTime = Date.now();
  console.error(`[HireIn MCP] ▶ Calling ${toolName} → ${url}`);

  try {
    // Firebase v2 callables expect payload wrapped in { data: ... }
    const response = await axios.post(
      url,
      { data: toolArgs },
      {
        timeout: 30000, // 30s timeout for Gemini-powered functions
        headers: { "Content-Type": "application/json" },
      }
    );

    const elapsed = Date.now() - startTime;

    // Firebase callables return results wrapped in { result: ... }
    const responseData = response.data?.result || response.data?.data || response.data;

    console.error(`[HireIn MCP] ✅ ${toolName} completed in ${elapsed}ms`);

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(responseData, null, 2),
        },
      ],
    };
  } catch (error: any) {
    const elapsed = Date.now() - startTime;
    console.error(`[HireIn MCP] ❌ ${toolName} failed after ${elapsed}ms: ${error.message}`);

    // Extract meaningful error from Firebase HTTP response if possible
    let errorMessage = error.message;
    if (error.response?.data?.error) {
      errorMessage =
        error.response.data.error.message ||
        JSON.stringify(error.response.data.error);
    }

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify({
            success: false,
            error: errorMessage,
            tool: toolName,
            elapsedMs: elapsed,
          }),
        },
      ],
      isError: true,
    };
  }
});

// ─── Start Server ───
async function run() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("═══════════════════════════════════════════════════");
  console.error("  HireIn MCP Bridge Server v2.0 — Running on stdio");
  console.error("  Tools registered: " + FIREBASE_TOOLS.length);
  console.error("  Firebase project: hirein-4");
  console.error("═══════════════════════════════════════════════════");
}

run().catch((error) => {
  console.error("Fatal error running MCP Server:", error);
  process.exit(1);
});
