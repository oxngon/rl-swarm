import { NextRequest, NextResponse } from "next/server";
import fs from "fs/promises";
import path from "path";

export async function POST(req: NextRequest) {
  try {
    // Parse the request body
    const body = await req.json();
    const { peerId } = body;

    if (!peerId) {
      return NextResponse.json({ error: "peerId required" }, { status: 400 });
    }

    // Read userData.json
    const userDataPath = path.join(process.cwd(), "temp-data", "userData.json");
    const userDataRaw = await fs.readFile(userDataPath, "utf-8");
    const userData = JSON.parse(userDataRaw);

    // Register peer in userData (add to array or set)
    if (!userData.peers) {
      userData.peers = [];
    }
    if (!userData.peers.includes(peerId)) {
      userData.peers.push(peerId);
    }

    // Write back
    await fs.writeFile(userDataPath, JSON.stringify(userData, null, 2));

    return NextResponse.json({ success: true, peerId });
  } catch (error) {
    console.error("register-peer error:", error);
    return NextResponse.json({ error: "Internal server error" }, { status: 500 });
  }
}
