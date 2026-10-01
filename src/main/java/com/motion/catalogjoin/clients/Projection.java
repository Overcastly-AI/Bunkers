package com.motion.catalogjoin.clients;

import com.motion.catalogjoin.Rows;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

/**
 * Selects a client's fields from a published document. A spec is a comma-separated list of
 * entries, each an expression with an optional {@code as name}:
 *
 * <pre>
 * itemNo,
 * item.DESCR as description,
 * manufacturer.name.MFR_NAME as manufacturer,
 * stepProducts[].attributes.UPC_NO[].value as upc,
 * sum(dcStock[].balance.QTY_ON_HAND) as dcQuantity,
 * positive(sum(dcStock[].balance.QTY_ON_HAND)) as inStock
 * </pre>
 *
 * A path walks object fields with {@code .}; {@code []} after a field walks every element of that
 * array, so the result is a list. Functions take one expression: {@code sum}, {@code min}, {@code
 * max} (numbers, which may arrive as strings), {@code count} (non-null values), {@code first},
 * {@code distinct}, and {@code positive} (true when the number is above zero). Without {@code as},
 * the field is named after the path's last segment.
 */
public final class Projection {

  private static final Set<String> FUNCTIONS = Set.of("sum", "min", "max", "count", "first", "distinct", "positive");

  private record Field(String name, Expression expression) {}

  private sealed interface Expression permits Path, Call {}

  private record Path(List<String> segments) implements Expression {}

  private record Call(String function, Expression argument) implements Expression {}

  private final String spec;
  private final List<Field> fields;

  private Projection(String spec, List<Field> fields) {
    this.spec = spec;
    this.fields = fields;
  }

  public static Projection parse(String spec) {
    List<Field> fields = new ArrayList<>();
    for (String entry : spec.split(",")) {
      String text = entry.trim();
      if (text.isEmpty()) {
        continue;
      }
      String[] parts = text.split("\\s+as\\s+");
      if (parts.length > 2) {
        throw new IllegalArgumentException("Bad field '" + text + "'");
      }
      Expression expression = expression(parts[0].trim(), text);
      String name = parts.length == 2 ? parts[1].trim() : defaultName(expression);
      if (fields.stream().anyMatch(f -> f.name().equals(name))) {
        throw new IllegalArgumentException("Field name '" + name + "' is used twice in '" + spec + "'");
      }
      fields.add(new Field(name, expression));
    }
    if (fields.isEmpty()) {
      throw new IllegalArgumentException("No fields in '" + spec + "'");
    }
    return new Projection(spec, List.copyOf(fields));
  }

  private static Expression expression(String text, String entry) {
    int open = text.indexOf('(');
    if (open > 0 && text.endsWith(")")) {
      String function = text.substring(0, open).trim().toLowerCase(java.util.Locale.ROOT);
      if (!FUNCTIONS.contains(function)) {
        throw new IllegalArgumentException("Unknown function '" + function + "' in '" + entry + "'; use one of " + FUNCTIONS);
      }
      return new Call(function, expression(text.substring(open + 1, text.length() - 1).trim(), entry));
    }
    if (!text.matches("[A-Za-z0-9_\\-]+(\\[])?(\\.[A-Za-z0-9_\\-]+(\\[])?)*")) {
      throw new IllegalArgumentException("Bad path '" + text + "' in '" + entry + "'");
    }
    return new Path(List.of(text.split("\\.")));
  }

  private static String defaultName(Expression expression) {
    return switch (expression) {
      case Path path -> path.segments().get(path.segments().size() - 1).replace("[]", "");
      case Call call -> defaultName(call.argument());
    };
  }

  /** The client's view of {@code doc} (published with keys sorted, like every document). */
  public Map<String, Object> apply(Map<String, Object> doc) {
    Map<String, Object> out = new LinkedHashMap<>();
    for (Field field : fields) {
      out.put(field.name(), evaluate(field.expression(), doc));
    }
    return out;
  }

  private static Object evaluate(Expression expression, Object doc) {
    return switch (expression) {
      case Path path -> walk(doc, path.segments(), 0);
      case Call call -> call(call.function(), evaluate(call.argument(), doc));
    };
  }

  private static Object walk(Object node, List<String> segments, int index) {
    if (index == segments.size()) {
      return node;
    }
    String segment = segments.get(index);
    boolean each = segment.endsWith("[]");
    Object value = node instanceof Map<?, ?> map ? map.get(each ? segment.substring(0, segment.length() - 2) : segment) : null;
    if (!each) {
      return walk(value, segments, index + 1);
    }
    List<Object> out = new ArrayList<>();
    if (value instanceof List<?> list) {
      for (Object element : list) {
        Object result = walk(element, segments, index + 1);
        if (result instanceof List<?> nested) {
          out.addAll(nested);
        } else if (result != null) {
          out.add(result);
        }
      }
    }
    return out;
  }

  private static Object call(String function, Object value) {
    List<?> values = value instanceof List<?> list ? list : value == null ? List.of() : List.of(value);
    List<BigDecimal> numbers = values.stream().map(Projection::number).filter(Objects::nonNull).toList();
    return switch (function) {
      case "sum" -> numbers.stream().reduce(BigDecimal.ZERO, BigDecimal::add);
      case "min" -> numbers.stream().min(Comparator.naturalOrder()).orElse(null);
      case "max" -> numbers.stream().max(Comparator.naturalOrder()).orElse(null);
      case "count" -> (long) values.stream().filter(Objects::nonNull).count();
      case "first" -> values.isEmpty() ? null : values.get(0);
      case "distinct" -> values.stream().filter(Objects::nonNull).distinct().toList();
      case "positive" -> !numbers.isEmpty() && numbers.get(0).signum() > 0;
      default -> throw new IllegalStateException(function);
    };
  }

  private static BigDecimal number(Object value) {
    if (value == null) {
      return null;
    }
    try {
      return new BigDecimal(Rows.text(value).trim());
    } catch (NumberFormatException e) {
      return null;
    }
  }

  @Override
  public String toString() {
    return spec;
  }
}
