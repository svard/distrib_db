defmodule DistribDb.Database do
  use Timex
  alias DistribDb.Database
  
  defstruct store: Map.new, expires_at: 0

  def new do
    %Database{}
  end

  def new(0) do
    %Database{}
  end
  
  def new(expire) do
    %Database{expires_at: Time.now(:secs) + expire}
  end

  def get(%Database{store: store}, key) do
    Map.get(store, key)
  end

  def put(%Database{store: store, expires_at: exp}, key, value) do
    %Database{store: Map.put(store, key, value), expires_at: exp}
  end

  def delete(%Database{store: store, expires_at: exp}, key) do
    %Database{store: Map.delete(store, key), expires_at: exp}
  end
  
  def expire_in(%Database{expires_at: timestamp}) do
    timestamp - Time.now(:secs)
  end
end
