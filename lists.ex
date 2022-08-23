defmodule DLists do
  def empty do
    fn tail -> tail end
  end

  def cons(x, dlist) do
    fn tail ->
      [x | dlist.(tail)]
    end
  end

  def snoc(dlist, x) do
    fn tail ->
      dlist.([x | tail])
    end
  end

  def append(dlist1, dlist2) do
    fn tail ->
      dlist1.(dlist2.(tail))
    end
  end

  def to_list(dlist) do
    dlist.([])
  end

  def from_list(list) do
    fn tail ->
      list ++ tail
    end
  end
end

defmodule Lists do
  defp flip(f) do
    fn a, b -> f.(b, a) end
  end

  def cons(x, xs) do
    [x | xs]
  end

  def foldl(f, zero, elems) do
    case elems do
      [] -> zero
      [head | tail] -> foldl(f, f.(zero, head), tail)
    end
  end

  def foldr(f, zero, elems) do
    case elems do
      [] -> zero
      [head | tail] -> f.(head, foldr(f, zero, tail))
    end
  end

  def reverse(elems) do
    foldl(flip(&cons/2), [], elems)
  end

  def unfoldl(f, seed) do
    unfoldl(f, seed, DLists.empty())
  end

  defp unfoldl(f, seed, dlist) do
    case f.(seed) do
      nil -> DLists.to_list(dlist)
      {elem, seed} -> unfoldl(f, seed, DLists.snoc(dlist, elem))
    end
  end

  def map(f, elems) do
    foldr(fn e, tail -> [f.(e) | tail] end, [], elems)
  end
end
