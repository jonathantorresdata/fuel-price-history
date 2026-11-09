{#- Generic test: every non-null value lies within [min_value, max_value]. -#}
{% test between(model, column_name, min_value, max_value) %}
SELECT {{ column_name }}
FROM {{ model }}
WHERE {{ column_name }} < {{ min_value }} OR {{ column_name }} > {{ max_value }}
{% endtest %}
