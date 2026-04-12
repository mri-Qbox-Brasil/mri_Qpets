import { create } from 'zustand';

interface UIState {
  isVisible: boolean;
  activeModal: string | null;
  activeTab: 'pets' | 'inventory' | 'shop';
  
  // Actions
  setVisible: (visible: boolean) => void;
  toggleVisible: () => void;
  setActiveModal: (modal: string | null) => void;
  setActiveTab: (tab: 'pets' | 'inventory' | 'shop') => void;
}

export const useUIStore = create<UIState>((set) => ({
  isVisible: false, // Will be controlled by NUI events
  activeModal: null,
  activeTab: 'pets',

  setVisible: (visible) => set({ isVisible: visible }),
  
  toggleVisible: () => set((state) => ({ isVisible: !state.isVisible })),
  
  setActiveModal: (modal) => set({ activeModal: modal }),
  
  setActiveTab: (tab) => set({ activeTab: tab })
}));
