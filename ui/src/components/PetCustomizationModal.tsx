import { useState, useEffect } from 'react';
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
  const [imageError, setImageError] = useState(false);

  // Reset local state when modal opens
  useEffect(() => {
    if (isOpen && petData) {
      console.log('[PetCustomizationModal] Opened for:', petData.item?.name || 'unknown');
      setCurrentName(petData.petInfo?.name || '');
      setCurrentVariation(0);
      setImageError(false);
      setError('');
    }
  }, [isOpen, petData]);

  if (!isOpen || !petData) return null;

  const handleNameChange = (value: string) => {
    setCurrentName(value);
    setError('');
    
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
    if (petData.variationList && petData.variationList.length > 0) {
      setVariation(petData.variationList[currentVariation]);
    }
    confirm();
  };

  const handleClose = async () => {
    const { fetchNui } = await import('../utils/fetchNui');
    await fetchNui('closeCustomization', { item: petData.item });
    closeCustomization();
  };

  const isInitialization = petData.type === 'init';

  const getPetImageUrl = (petName: string): string => {
    const resourceName = (window as any).GetParentResourceName?.() || 'mri_Qpets';
    return `nui://${resourceName}/inventory_images/${petName}.png`;
  };

  return (
    <div className="fixed inset-0 flex items-center justify-center z-[99999] p-4 pointer-events-auto">
      <Card className="w-full max-w-2xl border-border bg-card shadow-2xl animate-in fade-in zoom-in duration-300 pointer-events-auto overflow-hidden">
        <CardHeader className="border-b border-border bg-muted/30 p-10">
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="text-2xl font-black tracking-tight flex items-center gap-3">
                <Palette className="w-6 h-6 text-primary" />
                {isInitialization ? 'Personalizar Novo Pet' : 'Modificar Aparência'}
              </CardTitle>
              <CardDescription className="text-muted-foreground mt-1">
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

        <CardContent className="p-10 space-y-8 max-h-[70vh] overflow-y-auto custom-scrollbar">
          {/* Pet Preview */}
          <div className="flex justify-center">
            <div className="w-40 h-40 rounded-3xl bg-[#121419] border border-border/50 flex items-center justify-center p-6 shadow-2xl relative group overflow-hidden">
               <div className="absolute inset-0 bg-primary/5 opacity-0 group-hover:opacity-100 transition-opacity" />
               {!imageError ? (
                 <img 
                   src={getPetImageUrl(petData.item?.name || 'paw')} 
                   alt="Pet Preview" 
                   className="w-full h-full object-contain relative z-10 transition-transform group-hover:scale-110 duration-500"
                   onError={() => setImageError(true)}
                 />
               ) : (
                 <div className="text-6xl animate-bounce">🐾</div>
               )}
               <div className="absolute -bottom-4 -right-4 w-20 h-20 bg-primary/10 blur-3xl rounded-full" />
            </div>
          </div>

          {/* Nome do Pet */}
          {isInitialization && (
            <div className="space-y-3">
              <div className="flex items-center gap-2">
                <Type className="w-4 h-4 text-primary" />
                <Label htmlFor="petName" className="text-sm font-bold uppercase tracking-widest text-muted-foreground/80">Nome do Pet</Label>
              </div>
              <Input
                id="petName"
                value={currentName}
                onChange={(e) => handleNameChange(e.target.value)}
                placeholder="Digite o nome do seu pet..."
                maxLength={12}
                className="h-12 bg-muted/30 border-border/50 focus:border-primary text-lg"
              />
              {error && (
                <p className="text-sm text-destructive font-medium animate-pulse">{error}</p>
              )}
              <div className="flex justify-between items-center text-[10px] font-black uppercase tracking-widest text-muted-foreground/50">
                <span>Dica: Use um nome criativo</span>
                <span>{currentName.length}/12 caracteres</span>
              </div>
            </div>
          )}

          {/* Variações */}
          {petData.variationList && petData.variationList.length > 0 && (
            <div className="space-y-3">
              <div className="flex items-center gap-2">
                <Palette className="w-4 h-4 text-primary" />
                <Label className="text-sm font-bold uppercase tracking-widest text-muted-foreground/80">Aparência Disponível</Label>
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
                      <p className="text-[10px] font-black uppercase tracking-tighter opacity-50">Estilo</p>
                      <p className="text-sm font-bold">{index + 1}</p>
                    </div>
                    {currentVariation === index && (
                      <div className="absolute -top-2 -right-2 w-6 h-6 rounded-full bg-primary flex items-center justify-center shadow-lg shadow-primary/40 border-2 border-card">
                        <Check className="w-3 h-3 text-primary-foreground font-bold" />
                      </div>
                    )}
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Ações */}
          <div className="flex gap-4 pt-6">
            <Button
              variant="outline"
              onClick={handleClose}
              className="flex-1 h-12 font-black uppercase tracking-widest text-xs hover:bg-destructive/10 hover:text-destructive hover:border-destructive/30 transition-all"
            >
              Cancelar
            </Button>
            <Button
              onClick={handleConfirm}
              disabled={isInitialization && (!currentName.trim() || !!error)}
              className="flex-1 h-12 gap-2 font-black uppercase tracking-widest text-xs shadow-lg shadow-primary/20"
            >
              <Check className="w-4 h-4" />
              Confirmar & Salvar
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
