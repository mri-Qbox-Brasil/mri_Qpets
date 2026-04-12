import { create } from 'zustand';
import type { Pet } from '../types';
import { fetchNui } from '../utils/fetchNui';
import { isEnvBrowser } from '../utils/misc';

interface PetsState {
  pets: Pet[];
  selectedPet: Pet | null;
  activePet: Pet | null;
  
  // Actions
  setPets: (pets: Pet[]) => void;
  selectPet: (petId: number | null) => void;
  updatePet: (petId: number, updates: Partial<Pet>) => void;
  setActivePet: (petId: number | null) => void;
  updatePetStats: (petId: number, stats: { hunger?: number; thirst?: number; happiness?: number }) => void;
  addXP: (petId: number, amount: number) => void;
  healPet: (petId: number, amount: number) => void;
  petAction: (petId: number, action: string) => void;
  removePet: (petId: number) => void;
  loadPets: () => Promise<void>;
}

export const usePetsStore = create<PetsState>((set, get) => ({
  pets: [],
  selectedPet: null,
  activePet: null,

  setPets: (pets) => {
    const activePet = pets.find(p => p.isActive) || null;
    set({ pets, activePet });
  },

  selectPet: (petId) => {
    const pet = petId ? get().pets.find(p => p.id === petId) || null : null;
    set({ selectedPet: pet });
  },

  updatePet: (petId, updates) => {
    set((state) => ({
      pets: state.pets.map(pet =>
        pet.id === petId ? { ...pet, ...updates } : pet
      ),
      selectedPet: state.selectedPet?.id === petId 
        ? { ...state.selectedPet, ...updates }
        : state.selectedPet,
      activePet: state.activePet?.id === petId
        ? { ...state.activePet, ...updates }
        : state.activePet
    }));
  },

  setActivePet: (petId) => {
    const pets = get().pets;
    
    // Remove active status from all pets
    const updatedPets = pets.map(p => ({ ...p, isActive: false }));
    
    // Set new active pet
    if (petId) {
      const petIndex = updatedPets.findIndex(p => p.id === petId);
      if (petIndex !== -1) {
        updatedPets[petIndex].isActive = true;
      }
    }

    set({
      pets: updatedPets,
      activePet: petId ? updatedPets.find(p => p.id === petId) || null : null
    });
  },

  updatePetStats: (petId, stats) => {
    get().updatePet(petId, stats);
  },

  addXP: (petId, amount) => {
    const pet = get().pets.find(p => p.id === petId);
    if (!pet) return;

    const newXP = pet.xp + amount;
    const xpForNextLevel = Math.floor(100 * Math.pow(1.5, pet.level - 1));
    
    let newLevel = pet.level;
    let remainingXP = newXP;

    // Check for level up
    if (newXP >= xpForNextLevel && pet.level < 30) {
      newLevel = pet.level + 1;
      remainingXP = newXP - xpForNextLevel;
    }

    get().updatePet(petId, { xp: remainingXP, level: newLevel });
  },

  healPet: (petId, amount) => {
    const pet = get().pets.find(p => p.id === petId);
    if (!pet) return;

    const newHealth = Math.min(pet.currentHealth + amount, pet.maxHealth);
    get().updatePet(petId, { currentHealth: newHealth });
  },

  petAction: async (petId, action) => {
    const pet = get().pets.find(p => p.id === petId);
    if (!pet) return;

    // Don't call backend in browser mode
    if (isEnvBrowser()) {
      // Local simulation for development
      switch (action) {
        case 'pet':
          get().updatePetStats(petId, { happiness: Math.min(100, pet.happiness + 15) });
          get().addXP(petId, 5);
          break;
        case 'feed':
          get().updatePetStats(petId, { hunger: Math.min(100, pet.hunger + 50) });
          get().addXP(petId, 10);
          break;
        case 'water':
          get().updatePetStats(petId, { thirst: Math.min(100, pet.thirst + 25) });
          get().addXP(petId, 5);
          break;
        case 'heal':
          get().healPet(petId, 25);
          break;
      }
      return;
    }

    // Call backend
    try {
      const result = await fetchNui<{ success: boolean; pet?: Pet }>('petAction', {
        petId,
        action
      });

      if (result.success && result.pet) {
        get().updatePet(petId, result.pet);
      }
    } catch (error) {
      console.error('Failed to perform pet action:', error);
    }
  },

  removePet: async (petId) => {
    if (isEnvBrowser()) {
      // Local simulation
      set((state) => ({
        pets: state.pets.filter(p => p.id !== petId),
        selectedPet: state.selectedPet?.id === petId ? null : state.selectedPet,
        activePet: state.activePet?.id === petId ? null : state.activePet
      }));
      return;
    }

    try {
      const result = await fetchNui<{ success: boolean }>('removePet', { petId });
      
      if (result.success) {
        set((state) => ({
          pets: state.pets.filter(p => p.id !== petId),
          selectedPet: state.selectedPet?.id === petId ? null : state.selectedPet,
          activePet: state.activePet?.id === petId ? null : state.activePet
        }));
      }
    } catch (error) {
      console.error('Failed to remove pet:', error);
    }
  },

  loadPets: async () => {
    if (isEnvBrowser()) {
      // Load mock data in browser mode
      const { mockPlayerPets } = await import('../data/mockData');
      get().setPets(mockPlayerPets);
      return;
    }

    try {
      const pets = await fetchNui<Pet[]>('getPets');
      get().setPets(pets || []);
    } catch (error) {
      console.error('Failed to load pets:', error);
      get().setPets([]);
    }
  }
}));
