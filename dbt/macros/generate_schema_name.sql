{#- Use the schema set in dbt_project.yml as is (staging, silver, gold). -#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {{ custom_schema_name if custom_schema_name is not none else target.schema }}
{%- endmacro %}
