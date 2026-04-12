import { useEffect } from 'react';
import { usePetsStore } from './stores/petsStore';
import { useUIStore } from './stores/uiStore';
import { useActionsStore } from './stores/actionsStore';
import { useCustomizationStore } from './stores/customizationStore';
import { useMenuStore } from './stores/menuStore';
import { useInputStore } from './stores/inputStore';
import { useNuiEvent } from './hooks/useNuiEvent';
import { PetCustomizationModal } from './components/PetCustomizationModal';
import { MenuDialog } from './components/MenuDialog';
import { InputDialog } from './components/InputDialog';
import type { Pet } from './types';
import { 
  Heart, 
  Utensils, 
  Droplets, 
  Smile, 
  TrendingUp, 
  Zap, 
  Target, 
  Trash2, 
  User, 
  List,
  Activity
} from 'lucide-react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './components/ui/card';
import { Button } from './components/ui/button';
import { Badge } from './components/ui/badge';
import { Progress } from './components/ui/progress';
import { Separator } from './components/ui/separator';
import { cn } from './lib/utils';

function App() {
  const { pets, selectedPet, selectPet, removePet, petAction, setPets, loadPets } = usePetsStore();
  const { isVisible } = useUIStore();
  const { cooldowns, setCooldown } = useActionsStore();
  const { openCustomization } = useCustomizationStore();
  const { openMenu } = useMenuStore();
  const { openInput } = useInputStore();

  // Listen for NUI events
  useNuiEvent<Pet[]>('setPets', (data) => {
    setPets(data);
  });

  useNuiEvent<Pet>('updatePet', (data) => {
    const store = usePetsStore.getState();
    store.updatePet(data.id, data);
  });

  // Listen for customization event
  useNuiEvent<any>('openCustomization', (data) => {
    console.log('[App] Received openCustomization event:', data);
    openCustomization(data);
  });

  // Listen for menu events
  useNuiEvent<any>('openMenu', (data) => {
    console.log('[App] Opening menu:', data.title);
    openMenu(data.title, data.items, data.description);
  });

  // Listen for input events
  useNuiEvent<any>('openInput', (data) => {
    console.log('[App] Opening input:', data.title);
    openInput(data.title, data.fields, data.callbackEvent, data.description);
  });

  // Load pets on mount
  useEffect(() => {
    loadPets();
  }, [loadPets]);

  // Customization modal should always be available
  // Main UI only shows when isVisible is true

  // Generate pet image URL from ox_inventory
  const getPetImageUrl = (petName: string): string => {
    const resourceName = (window as any).GetParentResourceName?.() || 'mri_Qpets';
    return `nui://${resourceName}/inventory_images/${petName}.png`;
  };

  const getPetIcon = (distinct: string, petName: string) => {
    const d = distinct.toLowerCase();
    const imageUrl = getPetImageUrl(petName);
    
    return (
      <img 
        src={imageUrl} 
        alt={petName}
        className="w-full h-full object-cover"
        onError={(e) => {
          // Fallback to emoji if image fails to load
          const target = e.target as HTMLImageElement;
          target.style.display = 'none';
          const parent = target.parentElement;
          if (parent) {
            let emoji = '🐾';
            if (d.includes('dog')) emoji = '🐕';
            else if (d.includes('cat')) emoji = '🐱';
            else if (d.includes('hen')) emoji = '🐔';
            else if (d.includes('rabbit')) emoji = '🐰';
            parent.textContent = emoji;
          }
        }}
      />
    );
  };

  const getHealthPercentage = (current: number, max: number) => (current / max) * 100;

  const handlePetAction = (petId: number, action: string, cooldown: number) => {
    if (cooldowns[action]) return;
    petAction(petId, action);
    setCooldown(action, cooldown);
  };

  return (
    <>
      {/* Modals - Always rendered */}
      <PetCustomizationModal />
      <MenuDialog />
      <InputDialog />
      
      {/* Main Pet Management UI - Only when visible */}
      {isVisible && (
        <div className="h-full w-full flex items-center justify-end p-8 pointer-events-none">
          {/* Container que expande conforme necessário */}
          <div className={cn(
            "flex gap-4 transition-all duration-300 ease-in-out h-full max-h-[85vh] pointer-events-auto",
            selectedPet ? "w-[1100px]" : "w-[400px]"
          )}>
         
         {/* Detalhes do Pet - Aparece à esquerda quando selecionado */}
         {selectedPet && (
          <div className="flex-1 animate-in fade-in transition-all duration-300">
            <Card className="h-full flex flex-col border-border overflow-hidden bg-card/95 backdrop-blur-sm shadow-2xl">
              <CardHeader className="border-b border-border bg-muted/30 pb-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-12 h-12 rounded-lg bg-primary/10 flex items-center justify-center text-2xl border border-primary/20 overflow-hidden">
                      {getPetIcon(selectedPet.distinct, selectedPet.name)}
                    </div>
                    <div>
                      <CardTitle className="text-xl flex items-center gap-2">
                        {selectedPet.customName || selectedPet.model}
                        <Badge variant="secondary" className="text-[10px] font-bold uppercase tracking-wider">
                           ID: {selectedPet.id}
                        </Badge>
                      </CardTitle>
                      <CardDescription>{selectedPet.model}</CardDescription>
                    </div>
                  </div>
                  <div className="flex gap-2">
                    <Button 
                      variant="destructive" 
                      size="sm" 
                      className="gap-2 h-8"
                      onClick={() => removePet(selectedPet.id)}
                    >
                      <Trash2 className="w-4 h-4" />
                      Dispensar
                    </Button>
                  </div>
                </div>
              </CardHeader>
              
              <CardContent className="p-6 flex-1 overflow-y-auto space-y-8 custom-scrollbar">
                {/* Stats Grid */}
                <div className="grid grid-cols-4 gap-4">
                  {[
                    { 
                      label: 'Saúde', 
                      value: getHealthPercentage(selectedPet.currentHealth, selectedPet.maxHealth), 
                      display: `${selectedPet.currentHealth}/${selectedPet.maxHealth}`, 
                      colorVar: '--stat-health',
                      icon: <Activity className="w-4 h-4" /> 
                    },
                    { 
                      label: 'Fome', 
                      value: selectedPet.hunger, 
                      display: `${selectedPet.hunger}%`, 
                      colorVar: '--stat-hunger',
                      icon: <Utensils className="w-4 h-4" /> 
                    },
                    { 
                      label: 'Sede', 
                      value: selectedPet.thirst, 
                      display: `${selectedPet.thirst}%`, 
                      colorVar: '--stat-thirst',
                      icon: <Droplets className="w-4 h-4" /> 
                    },
                    { 
                      label: 'Felicidade', 
                      value: selectedPet.happiness, 
                      display: `${selectedPet.happiness}%`, 
                      colorVar: '--stat-happiness',
                      icon: <Smile className="w-4 h-4" /> 
                    },
                  ].map((stat) => (
                    <div key={stat.label} className="bg-muted/30 border border-border/50 rounded-xl p-3 flex flex-col gap-2">
                      <div className="flex items-center justify-between text-muted-foreground">
                        <span className="text-[10px] font-bold uppercase tracking-wider">{stat.label}</span>
                        {stat.icon}
                      </div>
                      <div className="flex items-baseline justify-between">
                        <span 
                          className="text-xl font-black" 
                          style={{ color: `var(${stat.colorVar})` }}
                        >
                          {stat.display}
                        </span>
                      </div>
                      <Progress 
                        value={stat.value} 
                        className="h-1.5"
                        style={{ 
                          '--progress-bg': `color-mix(in srgb, var(${stat.colorVar}) 10%, transparent)`,
                          '--progress-indicator': `var(${stat.colorVar})`,
                        } as React.CSSProperties}
                      />
                    </div>
                  ))}
                </div>

                <Separator className="bg-border/50" />

                {/* Level & XP */}
                <div className="bg-muted/20 border border-border/50 rounded-xl p-5 space-y-4">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <div className="w-8 h-8 rounded-lg bg-primary/20 flex items-center justify-center text-primary border border-primary/30">
                        <TrendingUp className="w-4 h-4" />
                      </div>
                      <span className="text-sm font-bold">Progresso de Nível</span>
                    </div>
                    <span className="text-xs font-medium text-muted-foreground">
                      Level {selectedPet.level}
                    </span>
                  </div>
                  <div className="space-y-2">
                    <div className="flex justify-between text-[10px] font-bold uppercase tracking-widest text-muted-foreground">
                      <span>XP Atual</span>
                      <span>{selectedPet.xp} XP / {Math.floor(100 * Math.pow(1.5, selectedPet.level - 1))}</span>
                    </div>
                    <Progress value={(selectedPet.xp / Math.floor(100 * Math.pow(1.5, selectedPet.level - 1))) * 100} className="h-2 bg-primary/10" />
                  </div>
                </div>

                {/* Ações */}
                <div className="space-y-4">
                  <h3 className="text-sm font-bold flex items-center gap-2">
                    <Zap className="w-4 h-4 text-primary" />
                    Ações Disponíveis
                  </h3>
                  <div className="grid grid-cols-4 gap-3">
                    {[
                      { id: 'pet', icon: <User className="w-4 h-4" />, label: 'Acariciar', cooldown: 5000 },
                      { id: 'feed', icon: <Utensils className="w-4 h-4" />, label: 'Alimentar', cooldown: 1000 },
                      { id: 'water', icon: <Droplets className="w-4 h-4" />, label: 'Dar Água', cooldown: 1000 },
                      { id: 'heal', icon: <Heart className="w-4 h-4" />, label: 'Curar', cooldown: 2000 },
                    ].map((action) => (
                      <Button
                        key={action.id}
                        variant="secondary"
                        disabled={!!cooldowns[action.id]}
                        className="flex flex-col h-auto py-4 gap-2 border border-border/50 hover:border-primary/50 hover:bg-primary/5 bg-muted/30 group transition-all"
                        onClick={() => handlePetAction(selectedPet.id, action.id, action.cooldown)}
                      >
                        <div className={cn(
                          "transition-colors",
                          cooldowns[action.id] ? "text-muted-foreground/30" : "text-muted-foreground group-hover:text-primary"
                        )}>
                          {action.icon}
                        </div>
                        <span className="text-[10px] font-bold uppercase">{action.label}</span>
                      </Button>
                    ))}
                  </div>
                </div>

                {/* Skills */}
                {selectedPet.abilities?.canHunt && (
                  <div className="bg-muted/20 border border-border/50 rounded-xl p-4 flex items-center justify-between group hover:border-primary/30 transition-colors">
                    <div className="flex items-center gap-4">
                      <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary group-hover:scale-110 transition-transform">
                        <Target className="w-5 h-5" />
                      </div>
                      <div>
                        <h4 className="text-sm font-bold">Habilidade de Caça</h4>
                        <p className="text-xs text-muted-foreground">Status atual da habilidade</p>
                      </div>
                    </div>
                    <div className="text-right">
                      <span className="text-xl font-black text-primary">Nível {selectedPet.abilities.huntingLevel}</span>
                    </div>
                  </div>
                )}
              </CardContent>
            </Card>
          </div>
        )}

        {/* Sidebar - Fixa à Direita */}
        <div className="w-[400px] flex flex-col h-full animate-in fade-in duration-500">
          {/* Header */}
          <div className="flex items-center justify-between mb-6">
            <div className="flex items-center gap-3 px-1">
              <div className="w-10 h-10 rounded-xl bg-primary flex items-center justify-center shadow-lg shadow-primary/20">
                <span className="text-xl">🐾</span>
              </div>
              <div>
                <h1 className="text-xl font-black tracking-tight text-foreground uppercase">Gerenciar Pets</h1>
                <div className="flex items-center gap-2">
                  <div className="w-2 h-2 rounded-full bg-primary animate-pulse" />
                  <p className="text-[10px] font-bold text-muted-foreground uppercase opacity-70">
                    {pets.filter(p => p.isActive).length} / 1 ativos • {pets.length} total
                  </p>
                </div>
              </div>
            </div>
          </div>

          <Card className="flex-1 flex flex-col border-border overflow-hidden bg-card/95 backdrop-blur-sm shadow-2xl">
            <CardHeader className="border-b border-border bg-muted/30 py-4">
              <div className="flex items-center justify-between">
                <CardTitle className="text-xs font-black uppercase tracking-widest text-muted-foreground flex items-center gap-2">
                  <List className="w-3 h-3" />
                  Meus Pets
                </CardTitle>
                <div className="w-1.5 h-1.5 rounded-full bg-primary" />
              </div>
            </CardHeader>
            <CardContent className="p-0 flex-1 overflow-hidden">
              <div className="h-full overflow-y-auto custom-scrollbar p-2 space-y-2">
                {pets.map((pet) => (
                  <button
                    key={pet.id}
                    onClick={() => selectPet(pet.id)}
                    className={cn(
                      "w-full flex items-center gap-4 p-4 rounded-xl border transition-all duration-200 group text-left",
                      selectedPet?.id === pet.id
                        ? "bg-primary/10 border-primary/50 shadow-lg shadow-primary/5"
                        : "bg-muted/10 border-border/50 hover:bg-muted/30 hover:border-border"
                    )}
                  >
                    <div className={cn(
                      "w-12 h-12 rounded-lg flex items-center justify-center text-2xl transition-all overflow-hidden",
                      selectedPet?.id === pet.id ? "bg-primary/20 scale-110" : "bg-muted/50 group-hover:bg-muted"
                    )}>
                      {getPetIcon(pet.distinct, pet.name)}
                    </div>
                    
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between mb-1">
                        <span className="font-bold text-sm truncate">{pet.customName || pet.model}</span>
                        <div className="flex items-center gap-1.5">
                          <span className="text-[10px] font-black text-muted-foreground uppercase">Lvl {pet.level}</span>
                          {pet.isActive && <div className="w-1.5 h-1.5 rounded-full bg-primary" />}
                        </div>
                      </div>
                      
                      <div className="space-y-1.5">
                        <div className="flex justify-between text-[8px] font-black uppercase tracking-widest text-muted-foreground/50">
                          <span>HP</span>
                          <span className="text-primary">{pet.currentHealth}/{pet.maxHealth}</span>
                        </div>
                        <Progress value={getHealthPercentage(pet.currentHealth, pet.maxHealth)} className="h-1 bg-primary/10" />
                      </div>
                    </div>
                  </button>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
      )}
    </>
  );
}

export default App;
