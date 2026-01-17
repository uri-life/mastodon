import type { RecordOf } from 'immutable';

import type { ApiStatusReactionJSON } from 'mastodon/api_types/reactions';

type StatusReactionShape = Required<ApiStatusReactionJSON>;
export type StatusReaction = RecordOf<StatusReactionShape>;
