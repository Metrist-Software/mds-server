defmodule MdsCore.DeploymentTest do
  use ExUnit.Case, async: true

  test "topological sorting basics" do
    items = [
      {:a, [], "a"},
      {:b, [:a, :d], "b"},
      {:c, [], "c"},
      {:d, [:c], "d"}
    ]

    assert MdsCore.Deployment.topo_sort(items) == [
             {:c, [], "c"},
             {:d, [:c], "d"},
             {:a, [], "a"},
             {:b, [:a, :d], "b"}
           ]
  end
end
