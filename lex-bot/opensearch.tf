
provider "opensearch" {
  url = var.opensearch_endpoint
  aws_region = data.aws_region.current.name
  healthcheck         = false
}

resource "opensearch_index" "main" {
  for_each                       = toset(var.environments)
  name                           = "bedrock-kb-${lower(each.key != "" ? "${each.key}-" : "")}${lower(var.prefix)}-index"
  number_of_shards               = "2"
  number_of_replicas             = "0"
  index_knn                      = true
  index_knn_algo_param_ef_search = "512"
  mappings                       = jsonencode(
        {
      "properties": {
        "bedrock-knowledge-base-default-vector": {
          "type": "knn_vector",
          "dimension": 1024,
          "method": {
            "name": "hnsw",
            "engine": "faiss",
            "parameters": {
              "m": 16,
              "ef_construction": 512
            },
            "space_type": "l2"
          }
        },
        "AMAZON_BEDROCK_METADATA": {
          "type": "text",
          "index": false
        },
        "AMAZON_BEDROCK_TEXT_CHUNK": {
          "type": "text"
        },
        "id": {
          "type": "text"
        },
        "title": {
          "type": "text"
        },
        "url": {
          "type": "text"
        },
        "x-amz-bedrock-kb-data-source-id": {
          "type": "text"
        },
        "x-amz-bedrock-kb-source-uri": {
          "type": "text"
        }
      }
    }
  )

}