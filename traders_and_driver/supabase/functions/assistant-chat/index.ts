import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (request) => {
  const json = (body: Record<string, unknown>, status = 200) =>
    new Response(JSON.stringify(body), {
      status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return json({ error: "Use POST to send a message." }, 405);

  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) {
    return json({ error: "The assistant is not configured yet. Set OPENAI_API_KEY for this Supabase function." }, 503);
  }

  try {
    const body = await request.json();
    const incoming = body?.messages;
    if (!Array.isArray(incoming) || incoming.length === 0 || incoming.length > 20) {
      return json({ error: "Send between 1 and 20 chat messages." }, 400);
    }

    const messages = incoming.map((message: Record<string, unknown>) => {
      const role = message?.role;
      const content = message?.content;
      if ((role !== "user" && role !== "assistant") || typeof content !== "string" || !content.trim() || content.length > 4000) {
        throw new Error("Each message needs a supported role and text under 4,000 characters.");
      }
      return { role, content: content.trim() };
    });
    if (messages[messages.length - 1].role !== "user") {
      return json({ error: "The last message must be from the user." }, 400);
    }

    const response = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        model: Deno.env.get("OPENAI_MODEL") ?? "gpt-4.1-mini",
        instructions: "You are the TradeMaster in-app assistant. Help traders and drivers understand how to use this app, post loads, find and accept available loads, and communicate clearly. Be concise, friendly, and ask a short follow-up when needed. Do not claim to see account data or perform actions. Do not provide financial, legal, or investment advice. If the user asks for current app data, explain that you can only guide them through the app.",
        input: messages,
        max_output_tokens: 500,
      }),
    });
    const result = await response.json();
    if (!response.ok) {
      console.error("OpenAI request failed:", response.status, result);
      return json({ error: "The assistant could not answer right now. Please try again." }, 502);
    }

    const reply = (result.output ?? [])
      .filter((item: { type?: string }) => item.type === "message")
      .flatMap((item: { content?: Array<{ type?: string; text?: string }> }) => item.content ?? [])
      .filter((item: { type?: string }) => item.type === "output_text")
      .map((item: { text?: string }) => item.text ?? "")
      .join("\n")
      .trim();
    if (!reply) return json({ error: "The assistant returned an empty response. Please try again." }, 502);
    return json({ reply });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Invalid request.";
    return json({ error: message }, 400);
  }
});
