import { useEffect, useState } from 'react';
import { fetchNui } from './utils/fetchNui';
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
import { Progress } from './components/ui/progress';
import { Separator } from './components/ui/separator';
import { cn } from './lib/utils';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './components/ui/card';
import { Button } from './components/ui/button';
import { Badge } from './components/ui/badge';
import { MoreVertical, Plus, ArrowLeft } from 'lucide-react';

function App() {
  const { pets, selectedPet, selectPet, removePet, petAction, setPets, loadPets, spawnPet, despawnPet } = usePetsStore();
  const { isVisible, setVisible } = useUIStore();
  const [confirmDeleteId, setConfirmDeleteId] = useState<number | null>(null);
  const { cooldowns, setCooldown } = useActionsStore();
  const { openCustomization } = useCustomizationStore();
  const { openMenu } = useMenuStore();
  const { openInput } = useInputStore();

  const [isShopOpen, setIsShopOpen] = useState(false);
  const [shopPets, setShopPets] = useState<any[]>([]);
  const [playerJob, setPlayerJob] = useState<string>('unemployed');

  // Listen for NUI events
  useNuiEvent<boolean>('setVisible', (data) => {
    setVisible(data);
  });

  useNuiEvent<Pet[]>('setPets', (data) => {
    setPets(data);
  });

  useNuiEvent<any[]>('setShopPets', (data) => {
    setShopPets(data);
  });

  useNuiEvent<string>('setPlayerJob', (data) => {
    setPlayerJob(data);
  });

  // Browser mockup mock data
  useEffect(() => {
    if (!(window as any).invokeNative) {
      setShopPets([
        { index: 1, name: 'keepcompanionwesty', model: 'A_C_Westy', price: 1500, displayName: 'Westy', distinct: 'no dog' },
        { index: 2, name: 'keepcompanionshepherd', model: 'A_C_shepherd', price: 5000, displayName: 'Shepherd', distinct: 'yes dog' },
        { index: 3, name: 'keepcompanionrottweiler', model: 'A_C_Rottweiler', price: 6000, displayName: 'Rottweiler', distinct: 'yes dog' },
      ]);
      setPlayerJob('police');
    }
  }, []);

  // Auto-visible in browser
  useEffect(() => {
    if (!(window as any).invokeNative) {
      setVisible(true);
    }
  }, [setVisible]);

  // Global ESC key listener
  useEffect(() => {
    const keyHandler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        let closedSomething = false;

        // If customization modal is open, trigger its close/cancel flow
        const custStore = useCustomizationStore.getState();
        if (custStore.isOpen && custStore.petData) {
          fetchNui('closeCustomization', { item: custStore.petData.item });
          custStore.closeCustomization();
          closedSomething = true;
        }

        // If menu is open, close it
        const menuStore = useMenuStore.getState();
        if (menuStore.isOpen) {
          fetchNui('closeMenu');
          menuStore.closeMenu();
          closedSomething = true;
        }

        // If input is open, close it
        const inputStore = useInputStore.getState();
        if (inputStore.isOpen) {
          fetchNui('closeInput');
          inputStore.closeInput();
          closedSomething = true;
        }

        if (isVisible) {
          setVisible(false);
          fetchNui('hideFrame');
          closedSomething = true;
        }

        // Fallback safety if anything was stuck but visible was false
        if (!closedSomething) {
          fetchNui('hideFrame');
        }
      }
    };

    window.addEventListener('keydown', keyHandler);
    return () => window.removeEventListener('keydown', keyHandler);
  }, [isVisible, setVisible]);

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
    setVisible(false);
    fetchNui('hideFrame');
  };

  const triggerCommand = (commandId: string) => {
    fetchNui('clickMenuItem', { id: commandId });
    setVisible(false);
    fetchNui('hideFrame');
  };

  const isK9 = (model: string): boolean => {
    if (!model) return false;
    const m = model.toLowerCase();
    return m === 'a_c_k9' || m === 'a_c_shepherd' || m === 'a_c_rottweiler' || m === 'a_c_husky';
  };

  const isPlayerPolice = ['police', 'policia', 'sheriff', 'lspd', 'sasp', 'bcso', 'statepolice'].includes(playerJob?.toLowerCase());

  return (
    <>
      {/* Modals - Always rendered */}
      <PetCustomizationModal />
      <MenuDialog />
      <InputDialog />
      
      {/* Dev Mode Controls (Only in Browser) */}
      {!(window as any).invokeNative && (
        <div className="fixed top-4 left-1/2 -translate-x-1/2 flex gap-2 p-2 bg-card border border-border rounded-full z-[10000] shadow-xl animate-in slide-in-from-top-4 duration-500">
          <button 
            className="rounded-full px-4 h-8 text-[10px] font-bold uppercase tracking-wider flex items-center gap-2 bg-primary/20 border border-primary/30 text-primary hover:bg-primary/30 transition-all"
            onClick={() => openCustomization({
              item: { id: 1, label: 'Pug' },
              pet_metadata: { name: 'Bolinha', variation: 1 },
              pet_variation_list: ['Variação 1', 'Variação 2', 'Variação 3'],
              type: 'init'
            })}
          >
            <Zap className="w-3 h-3" />
            Mock Custom
          </button>
          <button 
            className="rounded-full px-4 h-8 text-[10px] font-bold uppercase tracking-wider flex items-center gap-2 bg-blue-500/20 border border-blue-500/30 text-blue-400 hover:bg-blue-500/30 transition-all"
            onClick={() => openMenu('Menu de Teste', [
              { id: '1', label: 'Opção 1', description: 'Descrição da opção 1', onClick: () => console.log('Opção 1') },
              { id: '2', label: 'Opção 2', description: 'Descrição da opção 2', onClick: () => console.log('Opção 2') },
            ], 'Este é um menu de teste para validar o layout')}
          >
            <List className="w-3 h-3" />
            Mock Menu
          </button>
          <button 
            className="rounded-full px-4 h-8 text-[10px] font-bold uppercase tracking-wider flex items-center gap-2 bg-amber-500/20 border border-amber-500/30 text-amber-400 hover:bg-amber-500/30 transition-all"
            onClick={() => openInput('Formulário de Teste', [
              { name: 'nome', label: 'Nome', placeholder: 'Digite seu nome...' },
              { name: 'idade', label: 'Idade', type: 'number', placeholder: 'Digite sua idade...' }
            ], 'testCallback', 'Preencha os dados abaixo para testar o input')}
          >
            <Activity className="w-3 h-3" />
            Mock Input
          </button>
        </div>
      )}

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
             <Card className="h-full flex flex-col border-border overflow-hidden bg-[#090a0d] shadow-2xl">
               <CardHeader className="border-b border-border bg-[#121419] p-8">
                 <div className="flex items-center justify-between">
                   <div className="flex items-center gap-4 bg-[#1C1F26]/50 p-4 rounded-2xl border border-border/40 shadow-inner">
                     <div className="w-14 h-14 rounded-xl bg-[#090a0d] flex items-center justify-center text-3xl border border-border/50 overflow-hidden shadow-inner">
                       {getPetIcon(selectedPet.distinct, selectedPet.name)}
                     </div>
                     <div className="space-y-1">
                       <CardTitle className="text-2xl flex items-center gap-3 font-black tracking-tight text-white">
                         {selectedPet.customName || selectedPet.model}
                         <span className="text-xs font-bold text-muted-foreground bg-muted/20 px-2 py-0.5 rounded-md uppercase tracking-widest">
                            ID: {selectedPet.id}
                         </span>
                       </CardTitle>
                       <CardDescription className="flex items-center gap-2 font-medium">
                         <span className="text-muted-foreground uppercase text-[10px] tracking-widest">{selectedPet.model}</span>
                         <Badge className="bg-[#0BB673]/20 text-[#0BB673] border-none font-black uppercase text-[9px] h-4 px-1.5">
                           {selectedPet.stage}
                         </Badge>
                       </CardDescription>
                     </div>
                   </div>
                    <div className="flex flex-col gap-2">
                      <Button 
                        variant="ghost" 
                        size="sm" 
                        className="gap-2 h-9 px-4 font-black uppercase text-[10px] tracking-widest bg-white/5 text-muted-foreground border border-border/20 hover:bg-white/10 hover:text-white transition-all shadow-lg"
                        onClick={() => selectPet(null)}
                      >
                        <ArrowLeft className="w-4 h-4" />
                        Voltar
                      </Button>
                      {selectedPet.isActive ? (
                        <Button 
                          variant="ghost" 
                          size="sm" 
                          className="gap-2 h-9 px-4 font-black uppercase text-[10px] tracking-widest bg-amber-500/10 text-amber-500 border border-amber-500/20 hover:bg-amber-500 hover:text-white transition-all shadow-lg"
                          onClick={() => despawnPet(selectedPet.id)}
                        >
                          <ArrowLeft className="w-4 h-4" />
                          Recolher
                        </Button>
                      ) : (
                        <Button 
                          variant="default" 
                          size="sm" 
                          className="gap-2 h-9 px-4 font-black uppercase text-[10px] tracking-widest bg-primary/20 text-primary border border-primary/30 hover:bg-primary/30 hover:text-white transition-all shadow-lg"
                          onClick={() => spawnPet(selectedPet.id)}
                        >
                          <Zap className="w-4 h-4" />
                          Chamar
                        </Button>
                      )}
                      <Button 
                        variant="destructive" 
                        size="sm" 
                        className="gap-2 h-9 px-4 font-black uppercase text-[10px] tracking-widest bg-red-500/10 text-red-500 border border-red-500/20 hover:bg-red-500 hover:text-white transition-all shadow-lg shadow-red-500/5"
                        onClick={() => setConfirmDeleteId(selectedPet.id)}
                      >
                        <Trash2 className="w-4 h-4" />
                        Dispensar
                      </Button>
                    </div>
                 </div>
               </CardHeader>
               
               <CardContent className="p-8 flex-1 overflow-y-auto space-y-10 custom-scrollbar bg-[#090a0d]">
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
                     <div key={stat.label} className="bg-[#121419] border border-border/50 rounded-2xl p-4 flex flex-col gap-3 group hover:border-primary/30 transition-all duration-300 shadow-xl">
                       <div className="flex items-center justify-between">
                         <span className="text-[9px] font-black uppercase tracking-[0.2em] text-muted-foreground/60">{stat.label}</span>
                         <div className="text-muted-foreground/40 group-hover:text-primary transition-colors">
                            {stat.icon}
                         </div>
                       </div>
                       <div className="flex items-baseline">
                         <span className="text-2xl font-black text-white tracking-tighter">
                           {stat.display}
                         </span>
                       </div>
                     </div>
                   ))}
                 </div>

                 {/* Level & XP */}
                 <div className="bg-[#121419] border border-border/50 rounded-2xl p-6 space-y-6 shadow-xl relative overflow-hidden group">
                   <div className="absolute top-0 right-0 p-8 opacity-[0.02] group-hover:opacity-[0.05] transition-opacity">
                     <TrendingUp className="w-32 h-32" />
                   </div>
                   
                   <div className="flex items-center justify-between relative z-10">
                     <div className="flex items-center gap-3">
                       <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center text-primary border border-primary/20">
                         <TrendingUp className="w-5 h-5" />
                       </div>
                       <div>
                         <h4 className="text-sm font-black uppercase tracking-widest text-white">Progresso de Nível</h4>
                         <p className="text-[10px] font-bold text-muted-foreground uppercase tracking-widest">Experiência acumulada</p>
                       </div>
                     </div>
                     <div className="text-right">
                       <span className="text-[10px] font-black text-muted-foreground uppercase tracking-widest block mb-1">Status</span>
                       <span className="text-lg font-black text-primary uppercase">Level {selectedPet.level}</span>
                     </div>
                   </div>
                   
                   <div className="space-y-3 relative z-10">
                     <div className="flex justify-between text-[10px] font-black uppercase tracking-[0.2em] text-muted-foreground/70">
                       <span>XP ATUAL</span>
                       <span className="text-foreground">{selectedPet.xp} XP / {Math.floor(100 * Math.pow(1.5, selectedPet.level - 1))}</span>
                     </div>
                     <Progress 
                       value={(selectedPet.xp / Math.floor(100 * Math.pow(1.5, selectedPet.level - 1))) * 100} 
                       className="h-1.5 bg-[#1C1F26] rounded-full border border-border/10" 
                       style={{ 
                         '--progress-indicator': '#0BB673',
                       } as React.CSSProperties}
                     />
                   </div>
                 </div>

                 {/* Skills */}
                 {selectedPet.abilities?.canHunt && (
                   <div className="bg-[#121419] border border-border/50 rounded-2xl p-6 flex items-center justify-between group hover:border-primary/30 transition-all duration-300 shadow-xl">
                     <div className="flex items-center gap-4">
                       <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center text-primary group-hover:scale-110 transition-transform">
                         <Target className="w-6 h-6" />
                       </div>
                       <div>
                         <h4 className="text-sm font-black uppercase tracking-widest text-white">Habilidade de Caça</h4>
                         <p className="text-[10px] font-bold text-muted-foreground uppercase tracking-widest">Status atual da habilidade</p>
                       </div>
                     </div>
                     <div className="text-right">
                       <span className="text-[10px] font-black text-muted-foreground uppercase tracking-widest block mb-1">Progresso</span>
                       <span className="text-2xl font-black text-primary">Nível {selectedPet.abilities.huntingLevel}</span>
                     </div>
                   </div>
                 )}

                 {/* Active Pet Controls & Interactions */}
                 {selectedPet.isActive && (
                   <div className="space-y-6 pt-6 border-t border-border/20">
                     <div>
                       <h4 className="text-xs font-black uppercase tracking-widest text-white mb-4 flex items-center gap-2">
                         <Activity className="w-4 h-4 text-primary" />
                         Interações de Cuidado
                       </h4>
                       <div className="grid grid-cols-2 gap-3">
                         <Button 
                           variant="outline" 
                           className="h-11 bg-white/5 border-border/40 text-xs font-black uppercase tracking-wider hover:bg-primary/20 hover:text-primary transition-all duration-300"
                           onClick={() => handlePetAction(selectedPet.id, 'feed', 5000)}
                           disabled={cooldowns['feed']}
                         >
                           Alimentar
                         </Button>
                         <Button 
                           variant="outline" 
                           className="h-11 bg-white/5 border-border/40 text-xs font-black uppercase tracking-wider hover:bg-primary/20 hover:text-primary transition-all duration-300"
                           onClick={() => handlePetAction(selectedPet.id, 'water', 5000)}
                           disabled={cooldowns['water']}
                         >
                           Dar Água
                         </Button>
                         <Button 
                           variant="outline" 
                           className="h-11 bg-white/5 border-border/40 text-xs font-black uppercase tracking-wider hover:bg-primary/20 hover:text-primary transition-all duration-300"
                           onClick={() => handlePetAction(selectedPet.id, 'pet', 3000)}
                           disabled={cooldowns['pet']}
                         >
                           Acariciar
                         </Button>
                         <Button 
                           variant="outline" 
                           className="h-11 bg-white/5 border-border/40 text-xs font-black uppercase tracking-wider hover:bg-primary/20 hover:text-primary transition-all duration-300"
                           onClick={() => handlePetAction(selectedPet.id, 'heal', 10000)}
                           disabled={cooldowns['heal']}
                         >
                           {selectedPet.currentHealth <= 0 ? 'Reanimar' : 'Curar'}
                         </Button>
                       </div>
                     </div>

                     <Separator className="bg-border/20" />

                     <div>
                       <h4 className="text-xs font-black uppercase tracking-widest text-white mb-4 flex items-center gap-2">
                         <Zap className="w-4 h-4 text-primary" />
                         Comandos Básicos
                       </h4>
                       <div className="grid grid-cols-2 gap-3">
                         <Button 
                           variant="outline" 
                           className="h-11 bg-white/5 border-border/40 text-xs font-black uppercase tracking-wider hover:bg-primary/20 hover:text-primary transition-all duration-300"
                           onClick={() => triggerCommand('Follow')}
                         >
                           Seguir
                         </Button>
                         <Button 
                           variant="outline" 
                           className="h-11 bg-white/5 border-border/40 text-xs font-black uppercase tracking-wider hover:bg-primary/20 hover:text-primary transition-all duration-300"
                           onClick={() => triggerCommand('Wait')}
                         >
                           Ficar / Parar
                         </Button>
                         <Button 
                           variant="outline" 
                           className="h-11 bg-white/5 border-border/40 text-xs font-black uppercase tracking-wider hover:bg-primary/20 hover:text-primary transition-all duration-300"
                           onClick={() => triggerCommand('There')}
                         >
                           Ir ao Local
                         </Button>
                         <Button 
                           variant="outline" 
                           className="h-11 bg-white/5 border-border/40 text-xs font-black uppercase tracking-wider hover:bg-primary/20 hover:text-primary transition-all duration-300"
                           onClick={() => triggerCommand('GetinCar')}
                         >
                           Entrar no Carro
                         </Button>
                       </div>
                     </div>

                     {/* Hunting Commands */}
                     {selectedPet.abilities?.canHunt && (
                       <>
                         <Separator className="bg-border/20" />
                         <div>
                           <h4 className="text-xs font-black uppercase tracking-widest text-white mb-4 flex items-center gap-2">
                             <Target className="w-4 h-4 text-primary" />
                             Comandos de Caça
                           </h4>
                           <div className="grid grid-cols-2 gap-3">
                             <Button 
                               variant="outline" 
                               className="h-11 bg-white/5 border-border/40 text-xs font-black uppercase tracking-wider hover:bg-primary/20 hover:text-primary transition-all duration-300"
                               onClick={() => triggerCommand('Hunt')}
                             >
                               Caçar Alvo
                             </Button>
                             <Button 
                               variant="outline" 
                               className="h-11 bg-white/5 border-border/40 text-xs font-black uppercase tracking-wider hover:bg-primary/20 hover:text-primary transition-all duration-300"
                               onClick={() => triggerCommand('HuntandGrab')}
                             >
                               Caçar & Trazer
                             </Button>
                           </div>
                         </div>
                       </>
                     )}

                     {/* K9 Commands */}
                     {isPlayerPolice && isK9(selectedPet.model) && (
                       <>
                         <Separator className="bg-border/20" />
                         <div>
                           <h4 className="text-xs font-black uppercase tracking-widest text-white mb-4 flex items-center gap-2">
                             <Zap className="w-4 h-4 text-primary" />
                             Operações K9
                           </h4>
                           <div className="grid grid-cols-2 gap-3">
                             <Button 
                               variant="outline" 
                               className="h-11 bg-white/5 border-border/40 text-xs font-black uppercase tracking-wider hover:bg-primary/20 hover:text-primary transition-all duration-300"
                               onClick={() => triggerCommand('SearchPerson')}
                             >
                               Revistar Pessoa
                             </Button>
                             <Button 
                               variant="outline" 
                               className="h-11 bg-white/5 border-border/40 text-xs font-black uppercase tracking-wider hover:bg-primary/20 hover:text-primary transition-all duration-300"
                               onClick={() => triggerCommand('SearchCar')}
                             >
                               Revistar Veículo
                             </Button>
                           </div>
                         </div>
                       </>
                     )}

                     <Separator className="bg-border/20" />

                     {/* Tricks */}
                     <div>
                       <h4 className="text-xs font-black uppercase tracking-widest text-white mb-4 flex items-center gap-2">
                         <Smile className="w-4 h-4 text-primary" />
                         Truques e Adestramento
                       </h4>
                       <div className="grid grid-cols-3 gap-2">
                         <Button 
                           variant="outline" 
                           className="h-10 bg-white/5 border-border/40 text-[10px] font-black uppercase tracking-widest hover:bg-primary/20 hover:text-primary transition-all duration-300"
                           onClick={() => triggerCommand('Beg')}
                         >
                           Pedir
                         </Button>
                         <Button 
                           variant="outline" 
                           className="h-10 bg-white/5 border-border/40 text-[10px] font-black uppercase tracking-widest hover:bg-primary/20 hover:text-primary transition-all duration-300"
                           onClick={() => triggerCommand('Paw')}
                         >
                           Dar a Pata
                         </Button>
                         <Button 
                           variant="outline" 
                           className="h-10 bg-white/5 border-border/40 text-[10px] font-black uppercase tracking-widest hover:bg-primary/20 hover:text-primary transition-all duration-300"
                           onClick={() => triggerCommand('Playdead')}
                         >
                           Se Fingir Morto
                         </Button>
                       </div>
                     </div>
                   </div>
                 )}
               </CardContent>
             </Card>
          </div>
        )}

          <div className="w-[400px] h-full animate-in slide-in-from-right duration-300">
            {isShopOpen ? (
              <Card className="h-full flex flex-col bg-card border-border overflow-hidden shadow-2xl p-6">
                <div className="flex items-center justify-between mb-6">
                  <div className="flex items-center gap-3">
                    <div className="text-primary">
                      <Plus className="w-5 h-5" />
                    </div>
                    <h1 className="text-xs font-black tracking-widest text-muted-foreground uppercase">Loja de Pets</h1>
                  </div>
                  <Button 
                    variant="ghost" 
                    size="sm" 
                    className="font-black uppercase text-[10px] tracking-widest border border-border/20 bg-white/5 hover:bg-white/10 text-white"
                    onClick={() => setIsShopOpen(false)}
                  >
                    Voltar
                  </Button>
                </div>

                <div className="flex-1 overflow-y-auto custom-scrollbar pr-2 space-y-4">
                  {shopPets.map((pet) => (
                    <Card key={pet.index} className="border-border/50 bg-[#121419] overflow-hidden group">
                      <CardContent className="p-4 flex items-center justify-between">
                        <div className="flex items-center gap-3">
                          <div className="w-12 h-12 rounded-lg bg-[#1C1F26] flex items-center justify-center text-primary border border-border/50 overflow-hidden">
                            {getPetIcon(pet.distinct, pet.name)}
                          </div>
                          <div className="space-y-0.5">
                            <h3 className="font-bold text-base text-foreground tracking-tight">{pet.displayName}</h3>
                            <p className="text-[10px] font-bold text-primary uppercase tracking-wider">Preço: ${pet.price}</p>
                          </div>
                        </div>
                        <Button 
                          className="bg-primary/20 text-primary hover:bg-primary/30 border border-primary/30 font-black text-[10px] h-8 px-3 uppercase tracking-wider"
                          onClick={() => {
                            fetchNui('buyPet', { index: pet.index });
                            setIsShopOpen(false);
                            setVisible(false);
                            fetchNui('hideFrame');
                          }}
                        >
                          Comprar
                        </Button>
                      </CardContent>
                    </Card>
                  ))}
                </div>
              </Card>
            ) : (
              <Card className="h-full flex flex-col bg-card border-border overflow-hidden shadow-2xl p-6">
                <div className="flex items-center gap-3 mb-6 px-1">
                  <div className="text-primary">
                    <List className="w-5 h-5" />
                  </div>
                  <h1 className="text-xs font-black tracking-widest text-muted-foreground uppercase">Meus Pets</h1>
                </div>

                <div className="flex-1 overflow-y-auto custom-scrollbar pr-2 space-y-4">
                  {pets.map((pet) => (
                    <Card
                      key={pet.id}
                      className={cn(
                        "border-border/50 bg-[#121419] overflow-hidden group transition-all duration-300 cursor-pointer hover:border-primary/20",
                        selectedPet?.id === pet.id && "border-primary/50 shadow-lg shadow-primary/5"
                      )}
                      onClick={() => selectPet(pet.id)}
                    >
                      <CardContent className="p-4">
                        <div className="flex items-start justify-between mb-4">
                          <div className="flex items-center gap-3">
                            <div className="w-12 h-12 rounded-lg bg-[#1C1F26] flex items-center justify-center text-primary border border-border/50 overflow-hidden">
                              {getPetIcon(pet.distinct, pet.name)}
                            </div>
                            <div className="space-y-0.5">
                              <div className="flex items-center gap-2">
                                <h3 className="font-bold text-lg text-foreground tracking-tight">{pet.customName || pet.model}</h3>
                                <Badge 
                                  className="bg-[#0BB673]/20 text-[#0BB673] hover:bg-[#0BB673]/30 border-none font-black text-[8px] h-4 px-1.5 uppercase" 
                                >
                                  {pet.stage}
                                </Badge>
                              </div>
                              <p className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">LVL {pet.level}</p>
                            </div>
                          </div>
                          <Badge variant="outline" className={cn("border-border/40 text-[9px] font-bold uppercase", pet.isActive && "bg-primary/20 text-primary border-primary/30")}>
                            {pet.isActive ? "Ativo" : "Recolhido"}
                          </Badge>
                        </div>

                        <div className="space-y-2">
                          <div className="flex justify-between items-center text-[10px] font-black uppercase tracking-widest text-muted-foreground/70">
                            <span>PONTOS DE VIDA</span>
                            <span className="text-foreground">{pet.currentHealth} / {pet.maxHealth}</span>
                          </div>
                          <Progress 
                            value={getHealthPercentage(pet.currentHealth, pet.maxHealth)} 
                            className="h-2.5 bg-[#1C1F26] rounded-full border border-border/20"
                            style={{ 
                              '--progress-indicator': '#0BB673',
                            } as React.CSSProperties}
                          />
                        </div>
                      </CardContent>
                    </Card>
                  ))}

                  {/* Adicionar Novo Pet */}
                  <Card 
                    className="border-2 border-dashed border-border/50 bg-transparent hover:border-primary/50 hover:bg-primary/5 transition-all cursor-pointer animate-pulse duration-[3000ms]"
                    onClick={() => setIsShopOpen(true)}
                  >
                    <CardContent className="p-10 flex flex-col items-center justify-center gap-3">
                      <div className="w-10 h-10 rounded-full border-2 border-border/80 flex items-center justify-center text-muted-foreground">
                        <Plus className="w-6 h-6" />
                      </div>
                      <span className="text-xs font-black uppercase tracking-widest text-muted-foreground">ADICIONAR NOVO PET</span>
                    </CardContent>
                  </Card>
                </div>
              </Card>
            )}
          </div>
      </div>
    </div>
      )}

      {/* Modal de Confirmação para Dispensar Pet */}
      {confirmDeleteId !== null && (
        <div className="fixed inset-0 flex items-center justify-center z-[100000] p-4 bg-black/60 backdrop-blur-sm pointer-events-auto">
          <Card className="w-full max-w-md border-border bg-[#090a0d] shadow-2xl p-6 space-y-6 animate-in fade-in zoom-in duration-200">
            <div className="space-y-2 text-center">
              <h3 className="text-xl font-black text-white uppercase tracking-wider">Dispensar Companheiro</h3>
              <p className="text-sm text-muted-foreground">
                Tem certeza que deseja dispensar este pet? Essa ação não pode ser desfeita e ele será removido permanentemente.
              </p>
            </div>
            <div className="flex gap-4">
              <Button
                variant="outline"
                className="flex-1 h-11 font-black uppercase text-xs"
                onClick={() => setConfirmDeleteId(null)}
              >
                Cancelar
              </Button>
              <Button
                variant="destructive"
                className="flex-1 h-11 font-black uppercase text-xs"
                onClick={() => {
                  removePet(confirmDeleteId);
                  setConfirmDeleteId(null);
                }}
              >
                Confirmar
              </Button>
            </div>
          </Card>
        </div>
      )}
    </>
  );
}

export default App;
