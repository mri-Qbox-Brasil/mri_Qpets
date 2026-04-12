import { create } from 'zustand';
import { fetchNui } from '../utils/fetchNui';

interface CustomizationState {
  isOpen: boolean;
  petData: {
    item: any;
    petInfo: any;
    variationList: string[];
    type: 'init' | 'grooming';
  } | null;
  
  // Actions
  openCustomization: (data: any) => void;
  closeCustomization: () => void;
  setName: (name: string) => void;
  setVariation: (variation: string) => void;
  confirm: () => void;
}

export const useCustomizationStore = create<CustomizationState>((set, get) => ({
  isOpen: false,
  petData: null,

  openCustomization: (data) => {
    set({
      isOpen: true,
      petData: {
        item: data.item,
        petInfo: data.pet_metadatarmation,
        variationList: data.pet_variation_list || [],
        type: data.type
      }
    });
  },

  closeCustomization: () => {
    set({ isOpen: false, petData: null });
  },

  setName: (name) => {
    const { petData } = get();
    if (!petData) return;
    
    set({
      petData: {
        ...petData,
        item: {
          ...petData.item,
          metadata: {
            ...petData.item.metadata,
            name
          }
        }
      }
    });
  },

  setVariation: (variation) => {
    const { petData } = get();
    if (!petData) return;
    
    set({
      petData: {
        ...petData,
        item: {
          ...petData.item,
          metadata: {
            ...petData.item.metadata,
            variation
          }
        }
      }
    });
  },

  confirm: () => {
    const { petData } = get();
    if (!petData) return;
    
    // Send to backend
    fetchNui('confirmCustomization', {
      item: petData.item,
      type: petData.type
    }).then(() => {
      get().closeCustomization();
    });
  }
}));
