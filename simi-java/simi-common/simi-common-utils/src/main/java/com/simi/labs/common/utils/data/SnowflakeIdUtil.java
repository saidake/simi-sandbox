package com.simi.labs.common.utils.data;

import java.time.Instant;
import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.atomic.AtomicLong;

public final class SnowflakeIdUtil {
    // Custom epoch (2025-01-01T00:00:00Z)
    private static final long EPOCH = Instant.parse("2025-01-01T00:00:00Z").toEpochMilli();

    // Bit lengths
    private static final int NODE_ID_BITS = 10;
    private static final int SEQUENCE_BITS = 12;

    // Max values
    private static final long MAX_NODE_ID = (1L << NODE_ID_BITS) - 1; // 1023
    private static final long MAX_SEQUENCE = (1L << SEQUENCE_BITS) - 1; // 4095

    // Bit shifts
    private static final int TIMESTAMP_SHIFT = NODE_ID_BITS + SEQUENCE_BITS; // 22
    private static final int NODE_ID_SHIFT = SEQUENCE_BITS; // 12

    // Configuration
    private static final long NODE_ID;
    private static final AtomicLong sequence = new AtomicLong(0);
    private static volatile long lastTimestamp = -1L;

    static {
        // Configure node ID (e.g., from system property or default to 1)
        String nodeIdProp = System.getProperty("snowflake.node.id", "1");
        long nodeId = Long.parseLong(nodeIdProp);
        if (nodeId < 0 || nodeId > MAX_NODE_ID) {
            throw new IllegalArgumentException("Node ID must be between 0 and " + MAX_NODE_ID);
        }
        NODE_ID = nodeId;
    }

    private SnowflakeIdUtil() {
        // Prevent instantiation
    }

    public static synchronized long nextId() {
        long currentTimestamp = System.currentTimeMillis();

        if (currentTimestamp < lastTimestamp) {
            throw new RuntimeException("Clock moved backwards. Refusing to generate ID");
        }

        if (currentTimestamp == lastTimestamp) {
            // Same millisecond, increment sequence
            long seq = sequence.incrementAndGet() & MAX_SEQUENCE;
            if (seq == 0) {
                // Sequence overflow, wait for next millisecond
                currentTimestamp = waitUntilNextMillis(currentTimestamp);
            }
        } else {
            // New millisecond, reset sequence
            sequence.set(0);
        }

        lastTimestamp = currentTimestamp;

        // Compose ID: (timestamp - epoch) << 22 | nodeId << 12 | sequence
        return ((currentTimestamp - EPOCH) << TIMESTAMP_SHIFT)
                | (NODE_ID << NODE_ID_SHIFT)
                | (sequence.get() & MAX_SEQUENCE);
    }

    private static long waitUntilNextMillis(long currentTimestamp) {
        long nextTimestamp = System.currentTimeMillis();
        while (nextTimestamp <= currentTimestamp) {
            nextTimestamp = System.currentTimeMillis();
        }
        return nextTimestamp;
    }

    public static void main(String[] args) {
        // Test 1: Generate single-threaded IDs
        System.out.println("=== Test 1: Single-threaded ID generation ===");
        Set<Long> singleThreadIds = new HashSet<>();
        try {
            for (int i = 0; i < 1000; i++) {
                long id = SnowflakeIdUtil.nextId();
                singleThreadIds.add(id);
                if (i < 10) { // Print first 10 for brevity
                    System.out.println("id "+id);
                }
            }
            System.out.println("Generated " + singleThreadIds.size() + " unique IDs: " + (singleThreadIds.size() == 1000 ? "PASS" : "FAIL"));
        } catch (Exception e) {
            System.err.println("Test 1 failed: " + e.getMessage());
        }
    }
}