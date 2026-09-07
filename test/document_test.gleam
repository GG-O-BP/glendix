//// Exercises Mendix widget definition XML parsing and serialization.
////

import gleam/option
import gleam/string
import gleeunit/should
import glendix/define/document
import glendix/define/model

/// Verifies namespace-aware parsing preserves the complete widget model.
pub fn widget_xml_structural_round_trip_test() -> Nil {
  document.parse(representative_xml())
  |> should.equal(Ok(#(representative_meta(), representative_groups())))
}

/// Verifies serialization retains the established byte-exact Glendix layout.
pub fn widget_xml_byte_exact_serialization_test() -> Nil {
  document.serialize(representative_meta(), representative_groups())
  |> should.equal(representative_serialized_xml())
}

/// Verifies generated XML parses back to the same model.
pub fn widget_xml_generated_document_round_trip_test() -> Nil {
  let meta = representative_meta()
  let groups = representative_groups()

  document.serialize(meta, groups)
  |> document.parse
  |> should.equal(Ok(#(meta, groups)))
}

/// Verifies compatibility defaults and unknown property type handling.
pub fn widget_xml_empty_and_default_values_test() -> Nil {
  let source =
    "<?xml version=\"1.0\"?><widget><properties><propertyGroup><property key=\"fallback\" type=\"future\"><caption>Fallback</caption></property></propertyGroup></properties></widget>"
  let expected_meta =
    model.WidgetMeta(
      id: "",
      plugin_widget: False,
      offline_capable: False,
      supported_platform: "Web",
      needs_entity_context: False,
      name: "Unknown",
      description: "",
      studio_pro_category: option.None,
      help_url: option.None,
      icon: "",
      prompt: option.None,
    )
  let expected_property =
    model.Property(
      ..model.default_property("fallback", model.TypeString),
      caption: "Fallback",
      required: option.None,
      default_value: option.None,
      multiline: option.None,
    )

  document.parse(source)
  |> should.equal(
    Ok(
      #(expected_meta, [
        model.PropertyGroup("", [model.PropItem(expected_property)]),
      ]),
    ),
  )
}

/// Verifies malformed XML produces a descriptive domain error.
pub fn widget_xml_malformed_document_error_test() -> Nil {
  case document.parse("<widget><properties></widget>") {
    Error(document.MalformedWidgetXml(reason)) ->
      reason
      |> string.contains("ERROR Position")
      |> should.be_true
    Error(document.WidgetRootWasExpected(_)) | Ok(_) -> should.fail()
  }
}

/// Verifies a well-formed non-widget document is rejected explicitly.
pub fn widget_xml_wrong_root_error_test() -> Nil {
  document.parse("<package />")
  |> should.equal(Error(document.WidgetRootWasExpected("package")))
}

fn representative_xml() -> String {
  string.join(
    [
      "<?xml version=\"1.0\" encoding=\"utf-8\" ?>",
      "<!-- parser must ignore comments outside and inside the root -->",
      "<widget supportedPlatform=\"Web\" offlineCapable=\"true\"",
      "        xmlns=\"http://www.mendix.com/widget/1.0/\"",
      "        xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"",
      "        xsi:schemaLocation=\"http://www.mendix.com/widget/1.0/ ../node_modules/mendix/custom_widget.xsd\"",
      "        needsEntityContext=\"false\" pluginWidget=\"true\" id=\"example.widget\">",
      "    <name>Namespaced &amp; Widget</name>",
      "    <description><![CDATA[  Description <safe> & exact  ]]></description>",
      "    <icon><![CDATA[icon-data]]></icon>",
      "    <studioCategory>Fallback &amp; Category</studioCategory>",
      "    <helpUrl>https://example.com/help?a=1&amp;b=2</helpUrl>",
      "    <prompt><![CDATA[  Prompt <value>  ]]></prompt>",
      "    <properties>",
      "        <propertyGroup caption=\"General &amp; Data\">",
      "            <systemProperty key=\"Visibility\" />",
      "            <!-- attribute order must not matter -->",
      "            <property selectableObjects=\"CurrentObject\" defaultType=\"String\"",
      "                      setLabel=\"true\" onChange=\"refresh\" allowUpload=\"false\"",
      "                      dataSource=\"../items\" isList=\"true\" multiline=\"false\"",
      "                      defaultValue=\"one &amp; two\" required=\"true\"",
      "                      type=\"enumeration\" key=\"choice\">",
      "                <caption><![CDATA[Choice <caption>]]></caption>",
      "                <description>Choose &amp; continue</description>",
      "                <returnType assignableTo=\"Example.Entity\" type=\"String\" />",
      "                <enumerationValues>",
      "                    <enumerationValue key=\"first\">First &amp; Best</enumerationValue>",
      "                    <enumerationValue key=\"second\"><![CDATA[Second <Value>]]></enumerationValue>",
      "                </enumerationValues>",
      "                <attributeTypes>",
      "                    <attributeType name=\"String\" />",
      "                    <attributeType name=\"Integer\" />",
      "                </attributeTypes>",
      "                <associationTypes>",
      "                    <associationType name=\"Reference\" />",
      "                </associationTypes>",
      "                <selectionTypes>",
      "                    <selectionType name=\"Single\" />",
      "                    <selectionType name=\"Multi\" />",
      "                </selectionTypes>",
      "                <properties>",
      "                    <propertyGroup caption=\"Nested\">",
      "                        <property key=\"nested\" type=\"boolean\">",
      "                            <caption>Nested</caption>",
      "                            <description />",
      "                        </property>",
      "                    </propertyGroup>",
      "                </properties>",
      "            </property>",
      "            <systemProperty key=\"Name\" />",
      "        </propertyGroup>",
      "    </properties>",
      "</widget>",
    ],
    "\n",
  )
}

fn representative_meta() -> model.WidgetMeta {
  model.WidgetMeta(
    id: "example.widget",
    plugin_widget: True,
    offline_capable: True,
    supported_platform: "Web",
    needs_entity_context: False,
    name: "Namespaced & Widget",
    description: "Description <safe> & exact",
    studio_pro_category: option.Some("Fallback & Category"),
    help_url: option.Some("https://example.com/help?a=1&b=2"),
    icon: "icon-data",
    prompt: option.Some("Prompt <value>"),
  )
}

fn representative_groups() -> List(model.PropertyGroup) {
  [
    model.PropertyGroup(caption: "General & Data", items: [
      model.SysPropItem(model.SystemProperty("Visibility")),
      model.PropItem(
        model.Property(
          key: "choice",
          type_: model.TypeEnumeration,
          caption: "Choice <caption>",
          description: "Choose & continue",
          required: option.Some(True),
          default_value: option.Some("one & two"),
          multiline: option.Some(False),
          is_list: option.Some(True),
          data_source: option.Some("../items"),
          allow_upload: option.Some(False),
          on_change: option.Some("refresh"),
          set_label: option.Some(True),
          return_type: option.Some(model.ReturnType(
            "String",
            option.Some("Example.Entity"),
          )),
          enumeration_values: [
            model.EnumValue("first", "First & Best"),
            model.EnumValue("second", "Second <Value>"),
          ],
          attribute_types: ["String", "Integer"],
          association_types: ["Reference"],
          selection_types: ["Single", "Multi"],
          default_type: option.Some("String"),
          selectable_objects: option.Some("CurrentObject"),
          sub_properties: [
            model.PropertyGroup("Nested", [
              model.PropItem(
                model.Property(
                  ..model.default_property("nested", model.TypeBoolean),
                  caption: "Nested",
                  description: "",
                  required: option.None,
                  default_value: option.None,
                ),
              ),
            ]),
          ],
        ),
      ),
      model.SysPropItem(model.SystemProperty("Name")),
    ]),
  ]
}

fn representative_serialized_xml() -> String {
  string.join(
    [
      "<?xml version=\"1.0\" encoding=\"utf-8\" ?>",
      "<widget id=\"example.widget\" pluginWidget=\"true\" needsEntityContext=\"false\" offlineCapable=\"true\" supportedPlatform=\"Web\" xmlns=\"http://www.mendix.com/widget/1.0/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.mendix.com/widget/1.0/ ../node_modules/mendix/custom_widget.xsd\">",
      "    <name>Namespaced &amp; Widget</name>",
      "    <description>Description &lt;safe&gt; &amp; exact</description>",
      "    <icon>icon-data</icon>",
      "    <studioProCategory>Fallback &amp; Category</studioProCategory>",
      "    <helpUrl>https://example.com/help?a=1&amp;b=2</helpUrl>",
      "    <prompt>Prompt &lt;value&gt;</prompt>",
      "    <properties>",
      "        <propertyGroup caption=\"General &amp; Data\">",
      "            <systemProperty key=\"Visibility\" />",
      "            <property key=\"choice\" type=\"enumeration\" required=\"true\" defaultValue=\"one &amp; two\" multiline=\"false\" isList=\"true\" dataSource=\"../items\" allowUpload=\"false\" onChange=\"refresh\" setLabel=\"true\" defaultType=\"String\" selectableObjects=\"CurrentObject\">",
      "                <caption>Choice &lt;caption&gt;</caption>",
      "                <description>Choose &amp; continue</description>",
      "                <returnType type=\"String\" assignableTo=\"Example.Entity\" />",
      "                <enumerationValues>",
      "                    <enumerationValue key=\"first\">First &amp; Best</enumerationValue>",
      "                    <enumerationValue key=\"second\">Second &lt;Value&gt;</enumerationValue>",
      "                </enumerationValues>",
      "                <attributeTypes>",
      "                    <attributeType name=\"String\" />",
      "                    <attributeType name=\"Integer\" />",
      "                </attributeTypes>",
      "                <associationTypes>",
      "                    <associationType name=\"Reference\" />",
      "                </associationTypes>",
      "                <selectionTypes>",
      "                    <selectionType name=\"Single\" />",
      "                    <selectionType name=\"Multi\" />",
      "                </selectionTypes>",
      "                <properties>",
      "                    <propertyGroup caption=\"Nested\">",
      "                        <property key=\"nested\" type=\"boolean\">",
      "                            <caption>Nested</caption>",
      "                            <description></description>",
      "                        </property>",
      "                    </propertyGroup>",
      "                </properties>",
      "            </property>",
      "            <systemProperty key=\"Name\" />",
      "        </propertyGroup>",
      "    </properties>",
      "</widget>",
      "",
    ],
    "\n",
  )
}
