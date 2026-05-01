import { cn } from '@/lib/utils';
import React from 'react';

type Variant = 'default' | 'secondary' | 'destructive' | 'outline';

const variantClasses: Record<Variant, string> = {
  default: 'bg-primary text-primary-foreground',
  secondary: 'bg-secondary text-secondary-foreground',
  destructive: 'bg-destructive text-destructive-foreground',
  outline: 'border border-border text-foreground',
};

export const Badge = ({
  className,
  variant = 'default',
  children,
  ...props
}: React.HTMLAttributes<HTMLSpanElement> & { variant?: Variant }) => (
  <span
    className={cn('rounded-full px-2 py-0.5 text-xs font-semibold', variantClasses[variant], className)}
    {...props}
  >
    {children}
  </span>
);
