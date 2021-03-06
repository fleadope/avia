defmodule Snitch.Repo.Migrations.UpdateOrderStateType do
  use Ecto.Migration
  import Ecto.Query

  alias Snitch.Data.Schema
  alias Snitch.Repo

  def up do
    state_map =
      OrderStateEnum.__enum_map__()
      |> Enum.into(%{}, fn x -> {elem(x, 0) |> Atom.to_string(), elem(x, 1)} end)

    id_state_map =
      Repo.all(from(o in "snitch_orders", select: %{id: o.id, state: o.state}))
      |> Enum.map(fn x -> %{id: x.id, state: Map.get(state_map, x.state, 0)} end)

    alter_status =
      alter table("snitch_orders") do
        remove(:state)
        add(:state, OrderStateEnum.type(), null: false, default: 0)
      end

    flush()

    result =
      id_state_map
      |> Enum.into([], fn x ->
        with %{valid?: true} = changeset <-
               Ecto.Changeset.cast(%Schema.Order{id: x.id}, x, [:state]),
             {:ok, _} <- Repo.update(changeset) do
          :ok
        else
          _ ->
            :error
        end
      end)

    with false <- result |> Enum.any?(fn x -> x != :ok end),
         :ok <- alter_status do
      alter_status
    else
      _ ->
        Repo.rollback(result)
    end
  end

  def down do
    state_map =
      OrderStateEnum.__enum_map__()
      |> Enum.into(%{}, fn x -> {elem(x, 1), elem(x, 0) |> Atom.to_string()} end)

    id_state_map =
      Repo.all(from(p in "snitch_orders", select: %{id: p.id, state: p.state}))
      |> Enum.map(fn x -> %{id: x.id, state: Map.get(state_map, x.state, "cart")} end)

    alter_status =
      alter table("snitch_orders") do
        remove(:state)
        add(:state, :string, null: false, default: "cart")
      end

    flush()

    result =
      id_state_map
      |> Enum.into([], fn x ->
        with %{valid?: true} = changeset <-
               Ecto.Changeset.cast(%Schema.Order{id: x.id}, x, [:state]),
             {:ok, _} <- Repo.update(changeset) do
          :ok
        else
          _ ->
            :error
        end
      end)

    with false <- result |> Enum.any?(fn x -> x != :ok end),
         :ok <- alter_status do
      alter_status
    else
      _ ->
        Repo.rollback(result)
    end
  end
end
