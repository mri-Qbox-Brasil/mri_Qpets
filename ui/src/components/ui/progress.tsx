import * as React from "react"
import * as ProgressPrimitive from "@radix-ui/react-progress"

import { cn } from "@/lib/utils"

const Progress = React.forwardRef<
  React.ElementRef<typeof ProgressPrimitive.Root>,
  React.ComponentPropsWithoutRef<typeof ProgressPrimitive.Root>
>(({ className, value, style, ...props }, ref) => {
  const customStyle = style as any;
  const progressBg = customStyle?.['--progress-bg'] || 'hsl(var(--primary) / 0.2)';
  const progressIndicator = customStyle?.['--progress-indicator'] || 'hsl(var(--primary))';
  
  return (
    <ProgressPrimitive.Root
      ref={ref}
      className={cn(
        "relative h-2 w-full overflow-hidden rounded-full",
        className
      )}
      style={{
        backgroundColor: progressBg,
      }}
      {...props}
    >
      <ProgressPrimitive.Indicator
        className="h-full w-full flex-1 transition-all"
        style={{ 
          transform: `translateX(-${100 - (value || 0)}%)`,
          backgroundColor: progressIndicator
        }}
      />
    </ProgressPrimitive.Root>
  );
})
Progress.displayName = ProgressPrimitive.Root.displayName

export { Progress }
