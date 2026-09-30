package com.motion.catalogjoin.topology;

import com.motion.catalogjoin.Keys;
import com.motion.catalogjoin.Rows;
import com.motion.catalogjoin.model.Group;
import com.motion.catalogjoin.model.ItemDoc;
import com.motion.catalogjoin.model.ItemLocationDoc;
import com.motion.catalogjoin.model.LocatedBalance;
import com.motion.catalogjoin.model.StepClassification;
import com.motion.catalogjoin.model.StepProduct;
import com.motion.catalogjoin.model.StepValue;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

/**
 * Published document shapes (see docs/CONTRACTS.md). Internal state keeps rows in id-keyed maps;
 * the published form turns those into id-ordered arrays and names STEP attributes.
 */
final class Views {

  private final Map<String, List<String>> attributeNamesById = new TreeMap<>();

  Views(Map<String, String> attributeIdsByName) {
    attributeIdsByName.forEach(
        (name, id) -> attributeNamesById.computeIfAbsent(id, k -> new ArrayList<>()).add(name));
  }

  Map<String, Object> item(String key, ItemDoc doc) {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("itemNo", Keys.parse(key).get("ITEM_NO"));
    out.put("item", doc.item());
    out.put("manufacturer", doc.manufacturer());

    Map<String, Object> restrictions = new LinkedHashMap<>();
    restrictions.put("item", Group.valuesOf(doc.itemRules()));
    restrictions.put("manufacturer", Group.valuesOf(doc.manufacturerRules()));
    restrictions.put("manufacturerProductGroup", Group.valuesOf(doc.productGroupRules()));
    out.put("restrictions", restrictions);

    List<LocatedBalance> dcStock = Group.valuesOf(doc.dcStock());
    out.put("dcStock", dcStock);
    out.put("costs", Group.valuesOf(doc.costs()));

    List<Map<String, Object>> products = new ArrayList<>();
    for (StepProduct product : Group.valuesOf(doc.stepProducts())) {
      products.add(stepProduct(product));
    }
    out.put("stepProducts", products);
    return out;
  }

  Map<String, Object> stepProduct(StepProduct product) {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("stepProductId", product.stepProductId());
    out.put("product", product.product());

    Map<String, List<Map<String, Object>>> attributes = new TreeMap<>();
    for (StepValue value : Group.valuesOf(product.values())) {
      String attributeId = Rows.str(value.value(), "STEP_ATTRIBUTE_ID");
      for (String name : attributeNamesById.getOrDefault(attributeId, List.of())) {
        Map<String, Object> entry = new LinkedHashMap<>();
        entry.put("value", value.value().get("VALUE"));
        entry.put("stepUnitId", Rows.str(value.value(), "STEP_UNIT_ID"));
        entry.put("unit", value.unit());
        attributes.computeIfAbsent(name, k -> new ArrayList<>()).add(entry);
      }
    }
    out.put("attributes", attributes);

    List<Map<String, Object>> classifications = new ArrayList<>();
    for (StepClassification link : Group.valuesOf(product.classifications())) {
      Map<String, Object> entry = new LinkedHashMap<>();
      entry.put("stepClassificationId", Rows.str(link.link(), "STEP_CLASSIFICATION_ID"));
      entry.put("link", link.link());
      boolean known = link.classification() != null;
      entry.put("inWebHierarchy", known && link.classification().inWebHierarchy());
      entry.put("path", known ? link.classification().path() : List.of());
      classifications.add(entry);
    }
    out.put("classifications", classifications);
    return out;
  }

  Map<String, Object> itemLocation(String key, ItemLocationDoc doc) {
    Map<String, String> parts = Keys.parse(key);
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("itemNo", parts.get("ITEM_NO"));
    out.put("miLoc", parts.get("MI_LOC"));
    out.put("location", doc.location());
    out.put("balances", Group.valuesOf(doc.balances()));
    out.put("nonCosBalance", doc.nonCosBalance());
    out.put("localCosts", Group.valuesOf(doc.localCosts()));
    return out;
  }
}
