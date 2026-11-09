{#- Generic test: the combination of columns identifies each row. -#}
{% test unique_combination(model, columns) %}
SELECT {{ columns | join(', ') }}
FROM {{ model }}
GROUP BY {{ columns | join(', ') }}
HAVING count(*) > 1
{% endtest %}
