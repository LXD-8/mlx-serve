cask "mlx-core" do
  version "26.9.5"
  sha256 "b1e7c5e97b61db3e577129a625e6b0c66d1581ffbc9b6c09814c8c949d6c5035"

  url "https://github.com/ddalcu/mlx-serve/releases/download/v#{version}/MLXCore.dmg"
  name "MLX Core"
  desc "Native LLM server for Apple Silicon with OpenAI & Anthropic compatible APIs"
  homepage "https://github.com/ddalcu/mlx-serve"

  depends_on macos: :tahoe
  depends_on arch: :arm64

  app "MLX Core.app"

  zap trash: [
    "~/.mlx-serve",
  ]
end
