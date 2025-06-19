import Config

config :ai_devs,
  base_url: "base_url",
  api_key: "api_key",
  fine_tuned_model: "fine_tuned_model",
  public_endpoint: "public_endpoint",
  openai_api_key: "openai_api_key",
  qdrant_url: "qdrant_url",
  qdrant_api_key: "qdrant_api_key",
  jina_ai_url: "jina_ai_url",
  jina_ai_api_key: "jina_ai_api_key",
  neo4j_url: "neo4j_url",
  neo4j_user: "neo4j_user",
  neo4j_password: "neo4j_password",
  s01e01_robot_system_url: "robot_system_url",
  s01e01_robot_system_username: "robot_system_username",
  s01e01_robot_system_password: "robot_system_password",
  s04e03_url: "s04e03_url",
  s05e03_url: "s05e03_url",
  s05e03_password: "s05e03_password",
  s05e04_password: "s05e04_password"

import_config "secret.exs"
