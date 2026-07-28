import { useState } from 'react';
import { useInputStore } from '../stores/inputStore';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { X, Check } from 'lucide-react';
import { fetchNui } from '../utils/fetchNui';

export function InputDialog() {
  const { isOpen, title, description, fields, closeInput, submitInput } = useInputStore();
  const [formData, setFormData] = useState<Record<string, any>>({});
  const [errors, setErrors] = useState<Record<string, string>>({});

  if (!isOpen) return null;

  const handleSubmit = () => {
    const newErrors: Record<string, string> = {};

    // Validate required fields
    fields.forEach((field) => {
      if (field.required && !formData[field.name]) {
        newErrors[field.name] = `${field.label} é obrigatório`;
      }
      
      if (field.maxLength && formData[field.name]?.length > field.maxLength) {
        newErrors[field.name] = `Máximo ${field.maxLength} caracteres`;
      }
    });

    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors);
      return;
    }

    submitInput(formData);
    setFormData({});
    setErrors({});
  };

  const handleClose = () => {
    fetchNui('closeInput');
    closeInput();
    setFormData({});
    setErrors({});
  };

  return (
    <div className="fixed inset-0 flex items-center justify-center z-[9999] p-4 pointer-events-auto">
      <Card className="w-full max-w-lg border-border bg-card shadow-2xl animate-in fade-in zoom-in duration-300 pointer-events-auto">
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

        <CardContent className="p-10 space-y-8">
          {fields.map((field) => (
            <div key={field.name} className="space-y-2">
              <Label htmlFor={field.name} className="text-sm font-bold">
                {field.label}
                {field.required && <span className="text-destructive ml-1">*</span>}
              </Label>
              
              {field.type === 'select' && field.options ? (
                <select
                  id={field.name}
                  value={formData[field.name] || ''}
                  onChange={(e) => setFormData({ ...formData, [field.name]: e.target.value })}
                  className="w-full p-2 rounded-md border border-border bg-muted/30"
                >
                  <option value="">Selecione...</option>
                  {field.options.map((opt) => (
                    <option key={opt.value} value={opt.value}>
                      {opt.label}
                    </option>
                  ))}
                </select>
              ) : (
                <Input
                  id={field.name}
                  type={field.type || 'text'}
                  value={formData[field.name] || ''}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => 
                    setFormData({ ...formData, [field.name]: e.target.value })
                  }
                  placeholder={field.placeholder}
                  maxLength={field.maxLength}
                  className="bg-muted/30 border-border/50 focus:border-primary"
                />
              )}
              
              {errors[field.name] && (
                <p className="text-sm text-destructive font-medium">{errors[field.name]}</p>
              )}
            </div>
          ))}

          <div className="flex gap-3 pt-4">
            <Button
              variant="outline"
              onClick={handleClose}
              className="flex-1"
            >
              Cancelar
            </Button>
            <Button
              onClick={handleSubmit}
              className="flex-1 gap-2"
            >
              <Check className="w-4 h-4" />
              Confirmar
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
