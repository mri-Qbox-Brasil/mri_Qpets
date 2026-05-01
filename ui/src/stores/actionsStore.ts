import { create } from 'zustand';

interface ActionsState {
  cooldowns: Record<string, boolean>;
  setCooldown: (action: string, duration: number) => void;
}

export const useActionsStore = create<ActionsState>((set) => ({
  cooldowns: {},
  setCooldown: (action, duration) => {
    set((state) => ({
      cooldowns: { ...state.cooldowns, [action]: true }
    }));
    
    setTimeout(() => {
      set((state) => {
        const newCooldowns = { ...state.cooldowns };
        delete newCooldowns[action];
        return { cooldowns: newCooldowns };
      });
    }, duration);
  },
}));
