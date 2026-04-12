import { create } from 'zustand';

export interface MenuItem {
  id: string;
  label: string;
  description?: string;
  icon?: string;
  disabled?: boolean;
  onClick: () => void;
}

interface MenuState {
  isOpen: boolean;
  title: string;
  description?: string;
  items: MenuItem[];
  
  openMenu: (title: string, items: MenuItem[], description?: string) => void;
  closeMenu: () => void;
}

export const useMenuStore = create<MenuState>((set) => ({
  isOpen: false,
  title: '',
  description: undefined,
  items: [],

  openMenu: (title, items, description) => {
    set({
      isOpen: true,
      title,
      items,
      description
    });
  },

  closeMenu: () => {
    set({
      isOpen: false,
      title: '',
      items: [],
      description: undefined
    });
  }
}));
