import { create } from 'zustand';
import { fetchNui } from '../utils/fetchNui';

export interface InputField {
  name: string;
  label: string;
  type?: 'text' | 'number' | 'select';
  placeholder?: string;
  options?: { value: string; label: string }[];
  required?: boolean;
  maxLength?: number;
}

interface InputDialogState {
  isOpen: boolean;
  title: string;
  description?: string;
  fields: InputField[];
  callbackEvent?: string;
  
  openInput: (title: string, fields: InputField[], callbackEvent?: string, description?: string) => void;
  closeInput: () => void;
  submitInput: (data: Record<string, any>) => void;
}

export const useInputStore = create<InputDialogState>((set, get) => ({
  isOpen: false,
  title: '',
  description: undefined,
  fields: [],
  callbackEvent: undefined,

  openInput: (title, fields, callbackEvent, description) => {
    set({
      isOpen: true,
      title,
      fields,
      callbackEvent,
      description
    });
  },

  closeInput: () => {
    set({
      isOpen: false,
      title: '',
      fields: [],
      callbackEvent: undefined,
      description: undefined
    });
  },

  submitInput: (data) => {
    const { callbackEvent } = get();
    
    if (callbackEvent) {
      fetchNui(callbackEvent, data).then(() => {
        get().closeInput();
      });
    } else {
      get().closeInput();
    }
  }
}));
