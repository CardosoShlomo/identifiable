## 0.2.1

- Expand test coverage (typed/record ids, `updateById`, `indexWhereById`) and update the README for the generic API. No API changes.

## 0.2.0

- **BREAKING:** `Identifiable` is now generic over the id type — `Identifiable<I>` (records, ints, etc.). Mix `Identity` (`= Identifiable<String>`) or `Identifiable<String>` instead of bare `Identifiable`.
- Add `IdentifiableIterable.updateById` and `IdentifiableList.indexWhereById`.

## 0.1.1

- Add `hasSameId` (id-only check); `isSameAs` now also requires a matching `runtimeType`.

## 0.1.0

- Initial release.
- `Identifiable` mixin (`id`, `isSameAs`).
- `IdentifiableIterable`: `includes`, `overlaps`, `withoutId`, `byId`, `toMapById`.
- `IdentifiableMap`: `upsert`, `upsertAll`, `removeById`, `updateById`.
