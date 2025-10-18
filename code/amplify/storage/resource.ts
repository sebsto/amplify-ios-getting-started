import { defineStorage } from '@aws-amplify/backend';

export const storage = defineStorage({
  name: 'image',

  access: (allow) => ({
    'private/{entity_id}/*': [
      allow.entity('identity').to(['read', 'write', 'delete'])
    ],
  })
});