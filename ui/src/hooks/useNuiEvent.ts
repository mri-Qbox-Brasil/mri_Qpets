import { useEffect, useRef } from "react";

interface NuiMessageData<T = any> {
  action: string;
  data: T;
}

type NuiHandler<T> = (data: T) => void;

/**
 * A hook that listens for messages from the Lua side.
 *
 * @param action - The action name to listen for.
 * @param handler - The function to call when the action is received.
 */
export const useNuiEvent = <T = any>(action: string, handler: NuiHandler<T>) => {
  const savedHandler = useRef<NuiHandler<T>>(null);

  // Make sure we always have the latest handler
  useEffect(() => {
    savedHandler.current = handler;
  }, [handler]);

  useEffect(() => {
    const eventListener = (event: MessageEvent<NuiMessageData<T>>) => {
      const { action: eventAction, data } = event.data;

      if (savedHandler.current && eventAction === action) {
        savedHandler.current(data);
      }
    };

    window.addEventListener("message", eventListener);
    return () => window.removeEventListener("message", eventListener);
  }, [action]);
};
