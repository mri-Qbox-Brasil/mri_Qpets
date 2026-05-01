import { cn } from '@/lib/utils';
import React from 'react';

export const Card = ({ className, children, ...props }: React.ComponentProps<'div'>) => (
  <div
    className={cn(
      'rounded-lg border border-border bg-card shadow-2xl',
      className
    )}
    {...props}
  >
    {children}
  </div>
);

export const CardHeader = ({ className, children, ...props }: React.ComponentProps<'div'>) => (
  <div className={cn('border-b border-border bg-muted/30 pb-4', className)} {...props}>
    {children}
  </div>
);

export const CardTitle = ({ className, children, ...props }: React.ComponentProps<'h3'>) => (
  <h3 className={cn('font-bold text-xl', className)} {...props}>
    {children}
  </h3>
);

export const CardDescription = ({ className, children, ...props }: React.ComponentProps<'p'>) => (
  <p className={cn('text-muted-foreground', className)} {...props}>
    {children}
  </p>
);

export const CardContent = ({ className, children, ...props }: React.ComponentProps<'div'>) => (
  <div className={cn('p-6', className)} {...props}>
    {children}
  </div>
);
