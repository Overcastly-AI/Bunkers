package com.motion.catalogjoin.clients;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.motion.catalogjoin.Json;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

class ProjectionTest {

  private final Map<String, Object> doc = Json.read("""
      {"itemNo":"100","item":{"DESCR":"Bearing"},"manufacturer":{"name":{"MFR_NAME":"SKF"}},
       "dcStock":[{"balance":{"MI_LOC":"DC1","QTY_ON_HAND":"3"}},{"balance":{"MI_LOC":"DC2","QTY_ON_HAND":4.5}}],
       "stepProducts":[{"attributes":{"UPC_NO":[{"value":"0123"}]}}]}""");

  @Test
  void selectsPathsArraysAndFunctionsInConfiguredOrder() {
    Map<String, Object> view = Projection.parse("""
        itemNo, item.DESCR as description, manufacturer.name.MFR_NAME as manufacturer,
        dcStock[].balance.MI_LOC as locations, sum(dcStock[].balance.QTY_ON_HAND) as dcQuantity,
        positive(sum(dcStock[].balance.QTY_ON_HAND)) as inStock, count(dcStock[].balance.MI_LOC) as dcCount,
        first(stepProducts[].attributes.UPC_NO[].value) as upc""").apply(doc);
    assertThat(view.keySet()).containsExactly("itemNo", "description", "manufacturer", "locations", "dcQuantity", "inStock", "dcCount", "upc");
    assertThat(view).containsEntry("description", "Bearing").containsEntry("manufacturer", "SKF")
        .containsEntry("locations", List.of("DC1", "DC2")).containsEntry("inStock", true)
        .containsEntry("dcCount", 2L).containsEntry("upc", "0123");
    assertThat((BigDecimal) view.get("dcQuantity")).isEqualByComparingTo("7.5");
  }

  @Test
  void missingDataGivesNullsAndEmptyAggregates() {
    Map<String, Object> view = Projection.parse("manufacturer.profile.SELLABLE, sum(costs[].COST) as cost, "
        + "positive(sum(costs[].COST)) as priced, max(costs[].COST) as top").apply(Map.of("itemNo", "1"));
    assertThat(view).containsEntry("SELLABLE", null).containsEntry("priced", false).containsEntry("top", null);
    assertThat((BigDecimal) view.get("cost")).isEqualByComparingTo("0");
  }

  @Test
  void badSpecsFailAtStartup() {
    assertThatThrownBy(() -> Projection.parse("avg(x)")).hasMessageContaining("Unknown function");
    assertThatThrownBy(() -> Projection.parse("a, b.a")).hasMessageContaining("used twice");
    assertThatThrownBy(() -> Projection.parse("item..DESCR")).hasMessageContaining("Bad path");
  }
}
