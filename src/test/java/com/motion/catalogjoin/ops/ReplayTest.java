package com.motion.catalogjoin.ops;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.motion.catalogjoin.Keys;
import com.motion.catalogjoin.ops.DltReplay.Decision;
import com.motion.catalogjoin.ops.DltReplay.Origin;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.Set;
import org.apache.kafka.common.TopicPartition;
import org.junit.jupiter.api.Test;

class ReplayTest {

  @Test
  void republishKeysAreCanonicalAndCheckedAgainstTheDocumentType() {
    assertThat(Republish.key("item", "item_no= 100 ")).isEqualTo(Keys.of("ITEM_NO", "100"));
    assertThat(Republish.key("item-location", "MI_LOC=DC1,ITEM_NO=100")).isEqualTo(Keys.of("ITEM_NO", "100", "MI_LOC", "DC1"));
    assertThatThrownBy(() -> Republish.key("item", "ITEM_NO=1,MI_LOC=X")).hasMessageContaining("[ITEM_NO]");
    assertThatThrownBy(() -> Republish.key("item-location", "ITEM_NO=1")).hasMessageContaining("[ITEM_NO, MI_LOC]");
    assertThatThrownBy(() -> Republish.key("item", "100")).hasMessageContaining("Bad key");
  }

  @Test
  void requestsRoundTripAndMalformedOnesAreIgnored() {
    Republish.Request request = new Republish.Request("item", Set.of("client-qdrant"));
    assertThat(Republish.decode(Republish.encode(request))).isEqualTo(request);
    assertThat(request.wants("item", "client-qdrant")).isTrue();
    assertThat(request.wants("item", "item")).isFalse();
    assertThat(new Republish.Request("item", Set.of()).wants("item-location", "item-location")).isFalse();
    assertThat(Republish.decode("not json")).isNull();
    assertThat(Republish.decode("{\"outputs\":[]}")).isNull();
  }

  @Test
  void sourceDeadLettersAreReplayedOnlyWhenNothingNewerExistsForTheKey() {
    byte[] key = "{\"ITEM_NO\":\"1\"}".getBytes(StandardCharsets.UTF_8);
    Origin origin = new Origin(new TopicPartition("t", 0), 10);
    Map<ByteBuffer, Long> newer = Map.of(ByteBuffer.wrap(key.clone()), 12L);
    Map<ByteBuffer, Long> older = Map.of(ByteBuffer.wrap(key.clone()), 10L);
    assertThat(DltReplay.decide(key, origin, null, false)).isEqualTo(Decision.REPLAY);
    assertThat(DltReplay.decide(key, origin, older, false)).isEqualTo(Decision.REPLAY);
    assertThat(DltReplay.decide(key, origin, newer, false)).isEqualTo(Decision.SUPERSEDED);
    assertThat(DltReplay.decide(key, origin, newer, true)).isEqualTo(Decision.REPLAY);
    assertThat(DltReplay.decide(null, origin, null, false)).isEqualTo(Decision.NO_KEY);
    assertThat(DltReplay.decide(null, origin, null, true)).isEqualTo(Decision.REPLAY);
    assertThat(DltReplay.decide(key, null, null, true)).isEqualTo(Decision.NO_ORIGIN);
  }

  @Test
  void rejectedBatchesYieldCanonicalKeys() {
    assertThat(DltReplay.batchKeys("[{\"key\":{\"MI_LOC\":\"DC1\",\"ITEM_NO\":\"1\"},\"value\":{\"a\":1}},{\"key\":{\"ITEM_NO\":\"2\"},\"value\":null}]"))
        .containsExactly(Keys.of("ITEM_NO", "1", "MI_LOC", "DC1"), Keys.of("ITEM_NO", "2"));
  }
}
