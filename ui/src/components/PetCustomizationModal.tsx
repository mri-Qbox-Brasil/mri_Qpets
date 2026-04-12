import { useState } from 'react';
import { useCustomizationStore } from '../stores/customizationStore';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { X, Check, Palette, Type } from 'lucide-react';
import { cn } from '../lib/utils';

export function PetCustomizationModal() {
  const { isOpen, petData, closeCustomization, setName, setVariation, confirm } = useCustomizationStore();
  const [currentName, setCurrentName] = useState('');
  const [currentVariation, setCurrentVariation] = useState(0);
  const [error, setError] = useState('');

  // Debug logging
  console.log('[PetCustomizationModal] isOpen:', isOpen);
  console.log('[PetCustomizationModal] petData:', JSON.stringify(petData, null, 2));
  console.log('[PetCustomizationModal] Rendering:', !isOpen || !petData ? 'NO' : 'YES');

  if (!isOpen || !petData) return null;

  const handleNameChange = (value: string) => {
    setCurrentName(value);
    setError('');
    
    // Validate name
    if (value.length > 12) {
      setError('Nome muito longo (máximo 12 caracteres)');
      return;
    }
    
    if (value.includes(' ')) {
      setError('Nome não pode conter espaços');
      return;
    }
  };

  const handleConfirm = () => {
    if (!currentName.trim()) {
      setError('Digite um nome para seu pet');
      return;
    }

    setName(currentName);
    setVariation(petData.variationList[currentVariation]);
    confirm();
  };

  const handleClose = async () => {
    // Notify backend that modal was closed without confirmation
    const { fetchNui } = await import('../utils/fetchNui');
    await fetchNui('closeCustomization', { item: petData.item });
    
    // Only close after backend confirms
    closeCustomization();
  };

  const isInitialization = petData.type === 'init';

  return (
    <div className="fixed inset-0 bg-black/80 backdrop-blur-sm flex items-center justify-center z-[9999] p-4 pointer-events-auto">
      <Card className="w-full max-w-2xl border-border bg-card/95 backdrop-blur-sm shadow-2xl animate-in fade-in zoom-in duration-300 pointer-events-auto">
        <CardHeader className="border-b border-border bg-muted/30">
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="text-2xl flex items-center gap-2">
                <Palette className="w-6 h-6 text-primary" />
                {isInitialization ? 'Personalizar Novo Pet' : 'Modificar Aparência'}
              </CardTitle>
              <CardDescription>
                {isInitialization 
                  ? 'Escolha um nome e aparência para seu novo companheiro'
                  : 'Altere a aparência do seu pet'}
              </CardDescription>
            </div>
            <Button
              variant="ghost"
              size="icon"
              onClick={handleClose}
              className="hover:bg-destructive/20 hover:text-destructive"
            >
              <X className="w-5 h-6" />
            </Button>
          </div>
        </CardHeader>

        <CardContent className="p-6 space-y-6">
          {/* Nome do Pet */}
          {isInitialization && (
            <div className="space-y-3">
              <div className="flex items-center gap-2">
                <Type className="w-4 h-4 text-primary" />
                <Label htmlFor="petName" className="text-sm font-bold">Nome do Pet</Label>
              </div>
              <Input
                id="petName"
                value={currentName}
                onChange={(e) => handleNameChange(e.target.value)}
                placeholder="Digite o nome do seu pet..."
                maxLength={12}
                className="bg-muted/30 border-border/50 focus:border-primary"
              />
              {error && (
                <p className="text-sm text-destructive font-medium">{error}</p>
              )}
              <p className="text-xs text-muted-foreground">
                {currentName.length}/12 caracteres
              </p>
            </div>
          )}

          {/* Variações */}
          {petData.variationList && petData.variationList.length > 0 && (
            <div className="space-y-3">
              <div className="flex items-center gap-2">
                <Palette className="w-4 h-4 text-primary" />
                <Label className="text-sm font-bold">Aparência</Label>
              </div>
              <div className="grid grid-cols-4 gap-3">
                {petData.variationList.map((variation, index) => (
                  <button
                    key={index}
                    onClick={() => setCurrentVariation(index)}
                    className={cn(
                      "relative p-4 rounded-xl border-2 transition-all duration-200",
                      "hover:scale-105 hover:shadow-lg",
                      currentVariation === index
                        ? "border-primary bg-primary/10 shadow-lg shadow-primary/20"
                        : "border-border/50 bg-muted/30 hover:border-primary/50"
                    )}
                  >
                    <div className="text-center">
                      <p className="text-sm font-bold">Variação {index + 1}</p>
                      <p className="text-xs text-muted-foreground mt-1">{variation}</p>
                    </div>
                    {currentVariation === index && (
                      <div className="absolute -top-2 -right-2 w-6 h-6 rounded-full bg-primary flex items-center justify-center">
                        <Check className="w-4 h-4 text-primary-foreground" />
                      </div>
                    )}
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Ações */}
          <div className="flex gap-3 pt-4">
            <Button
              variant="outline"
              onClick={closeCustomization}
              className="flex-1"
            >
              Cancelar
            </Button>
            <Button
              onClick={handleConfirm}
              disabled={isInitialization && (!currentName.trim() || !!error)}
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
