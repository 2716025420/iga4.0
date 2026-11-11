class_name CalendarContent
extends RefCounted

## Authoring hook. Dates are intentionally empty until the writer assigns them.
## Each entry: id, month (1-12), day (day of month), phase (morning/afternoon/night), location, dialogue,
## optional required_flags and flags (applied once on completion).
## Calendar begins October 1; January-September dates follow the first December.
## Example schema only: {"id":"...","month":M,"day":D,"phase":"morning","location":"club","dialogue":"..."}
const STORY_DATES: Array[Dictionary] = []
