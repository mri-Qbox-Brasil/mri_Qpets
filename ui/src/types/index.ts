export interface Pet {
  id: number;
  name: string;
  model: string;
  customName?: string;
  distinct: string;
  currentHealth: number;
  maxHealth: number;
  hunger: number;
  thirst: number;
  happiness: number;
  level: number;
  xp: number;
  isActive: boolean;
  stage: 'Filhote' | 'Jovem' | 'Adulto';
  abilities: {
    canHunt: boolean;
    huntingLevel: number;
  };
}
