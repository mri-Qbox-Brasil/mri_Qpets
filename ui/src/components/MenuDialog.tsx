import { useMenuStore } from '../stores/menuStore';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { X } from 'lucide-react';
import { cn } from '../lib/utils';
import { fetchNui } from '../utils/fetchNui';

export function MenuDialog() {
  const { isOpen, title, description, items, closeMenu } = useMenuStore();

  if (!isOpen) return null;

  const handleClose = () => {
    fetchNui('closeMenu');
    closeMenu();
  };

  return (
    <div className="fixed inset-0 flex items-center justify-center z-[9999] p-4 pointer-events-auto">
      <Card className="w-full max-w-md border-border bg-card shadow-2xl animate-in fade-in zoom-in duration-300 pointer-events-auto">
        <CardHeader className="border-b border-border bg-muted/30 p-10">
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="text-2xl font-black tracking-tight">{title}</CardTitle>
              {description && <CardDescription className="text-muted-foreground mt-1">{description}</CardDescription>}
            </div>
            <Button
              variant="ghost"
              size="icon"
              onClick={handleClose}
              className="hover:bg-destructive/20 hover:text-destructive"
            >
              <X className="w-5 h-5" />
            </Button>
          </div>
        </CardHeader>

        <CardContent className="p-10 space-y-4 max-h-[60vh] overflow-y-auto">
          {items.map((item) => (
            <button
              key={item.id}
              onClick={() => {
                if (!item.disabled) {
                  fetchNui('clickMenuItem', { id: item.id });
                  closeMenu();
                }
              }}
              disabled={item.disabled}
              className={cn(
                "w-full p-4 rounded-lg border-2 transition-all duration-200 text-left",
                "hover:scale-[1.02] hover:shadow-lg",
                item.disabled
                  ? "border-border/30 bg-muted/20 opacity-50 cursor-not-allowed"
                  : "border-border/50 bg-muted/30 hover:border-primary/50 hover:bg-primary/5"
              )}
            >
              <div className="flex items-center gap-3">
                {item.icon && <span className="text-2xl">{item.icon}</span>}
                <div className="flex-1">
                  <p className="font-bold text-sm">{item.label}</p>
                  {item.description && (
                    <p className="text-xs text-muted-foreground mt-1">{item.description}</p>
                  )}
                </div>
              </div>
            </button>
          ))}
        </CardContent>
      </Card>
    </div>
  );
}
