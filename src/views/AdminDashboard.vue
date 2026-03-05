<template>
  <div class="flex h-screen overflow-hidden bg-slate-50 font-sans">
    <!-- Toasts -->
    <div class="fixed top-6 right-6 z-[200] flex flex-col gap-3 max-w-sm w-full">
      <div v-for="toast in toasts" :key="toast.id" 
           :class="['p-4 rounded-lg shadow-xl border-l-4 flex items-start gap-3 bg-white animate-in slide-in-from-right', 
                   toast.tipo === 'sucesso' ? 'border-green-500 text-green-800' : 'border-red-500 text-red-800']">
        <i :class="['ph text-2xl', toast.tipo === 'sucesso' ? 'ph-check-circle text-green-500' : 'ph-warning-circle text-red-500']"></i>
        <div class="flex-1 text-sm font-medium">{{ toast.mensagem }}</div>
      </div>
    </div>

    <!-- Sidebar -->
    <aside class="w-64 bg-[#113366] text-white flex flex-col shadow-lg z-10 transition-transform">
      <div class="p-6 border-b border-white/10 text-center">
        <h1 class="text-2xl font-bold flex flex-col items-center gap-1">
          <i class="ph ph-barcode text-[#ee4d2d] text-5xl"></i>
          <div>Ativos<span class="text-[#ee4d2d]">MG2</span></div>
        </h1>
        <p class="text-[10px] uppercase tracking-tighter opacity-50 font-bold">Gestão Quantitativa</p>
      </div>
      <nav class="flex-1 px-4 py-6 space-y-1">
        <button v-for="tab in tabs" :key="tab.id" @click="currentTab = tab.id" :class="navClass(tab.id)">
          <i :class="['ph text-xl', tab.icon]"></i> 
          <span>{{ tab.label }}</span>
          <span v-if="tab.id === 'transferencias' && pendingTransfersCount > 0" 
                class="ml-auto bg-[#ee4d2d] text-white text-[10px] w-5 h-5 flex items-center justify-center rounded-full font-black shadow-sm">
            {{ pendingTransfersCount }}
          </span>
        </button>
      </nav>
      <div class="px-4 pb-4 space-y-2">
        <!-- Admin ID Selection -->
        <div class="bg-white/5 p-3 rounded-xl border border-white/10">
          <p class="text-[9px] uppercase font-bold text-white/40 mb-2">Identificação Admin</p>
          <select v-model="adminUser" class="w-full bg-[#113366] text-white text-xs font-bold border-none outline-none focus:ring-0">
            <option value="" disabled>Quem está logado?</option>
            <option v-for="a in admins" :key="a" :value="a">{{ a }}</option>
          </select>
        </div>
        <button @click="currentTab = 'config'" :class="navClass('config')">
          <i class="ph ph-gear text-xl"></i>
          <span>Configurações</span>
        </button>
      </div>
      <div class="p-4 border-t border-white/5 text-center text-[10px] text-white/30 italic">v4.0 Quantidade</div>
    </aside>

    <!-- Main -->
    <main class="flex-1 overflow-y-auto p-8 relative">
      <div v-if="loading" class="fixed inset-0 bg-white/60 z-[100] flex flex-col items-center justify-center backdrop-blur-[1px]">
        <div class="w-12 h-12 border-4 border-slate-200 border-t-[#ee4d2d] rounded-full animate-spin mb-4"></div>
        <p class="text-[#113366] font-black text-sm animate-pulse tracking-widest uppercase">Processando...</p>
      </div>

      <!-- DASHBOARD TAB -->
      <div v-if="currentTab === 'dash'" class="space-y-6 max-w-7xl mx-auto animate-in fade-in zoom-in-95 duration-300">
        <div class="flex justify-between items-end bg-white p-6 rounded-2xl shadow-sm border border-slate-200">
          <div>
            <h2 class="text-3xl font-black text-[#113366] flex items-center gap-2">
              <i class="ph-fill ph-chart-line text-[#ee4d2d]"></i> Dashboard
            </h2>
            <p class="text-slate-400 text-sm font-medium">Controle total por quantidades e áreas.</p>
          </div>
          <button @click="fetchInitialData" :disabled="loading" class="bg-[#113366] text-white px-6 py-2.5 rounded-xl hover:bg-[#0c2447] flex items-center gap-2 shadow-lg transition-all font-bold group disabled:opacity-50">
            <i class="ph ph-arrows-clockwise text-xl group-hover:rotate-180 transition-transform duration-500"></i>
            Atualizar Agora
          </button>
        </div>

        <!-- KPI Cards -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
          <div v-for="kpi in kpiCards" :key="kpi.label" 
               class="bg-white p-6 rounded-2xl border border-slate-200 flex items-center gap-5 shadow-sm">
            <div :class="['p-4 rounded-xl', kpi.iconBg]">
              <i :class="['text-3xl', kpi.icon, kpi.iconColor]"></i>
            </div>
            <div>
              <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">{{ kpi.label }}</p>
              <p class="text-4xl font-black text-[#113366]">{{ kpi.value }}</p>
            </div>
          </div>
        </div>

        <!-- Area Inventory Breakdown -->
        <div class="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
          <div class="p-6 border-b border-slate-100 bg-slate-50/50">
            <h3 class="font-black text-[#113366] flex items-center gap-2">
              <i class="ph ph-factory text-[#ee4d2d]"></i> Estoque por Área
            </h3>
          </div>
          <div class="p-6 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <div v-for="area in inventoryByArea" :key="area.id" class="p-5 bg-slate-50 rounded-2xl border border-slate-100 flex flex-col gap-4">
              <div class="flex justify-between items-center">
                <span class="font-black text-[#113366] uppercase text-xs">{{ area.nome }}</span>
                <span class="text-[10px] font-bold text-slate-400">Total: {{ area.quantidade_total }}</span>
              </div>
              <div class="flex justify-between items-end">
                <div>
                  <p class="text-[10px] font-bold text-slate-400 uppercase">Disponível</p>
                  <p class="text-3xl font-black" :class="area.available > 0 ? 'text-green-600' : 'text-slate-300'">{{ area.available }}</p>
                </div>
                <div class="text-right">
                  <p class="text-[10px] font-bold text-slate-400 uppercase">Em Campo</p>
                  <p class="text-xl font-bold text-orange-500">{{ area.inUse }}</p>
                </div>
              </div>
              <div class="w-full h-2 bg-slate-200 rounded-full overflow-hidden">
                <div class="h-full bg-green-500 transition-all duration-1000" 
                     :style="{ width: (area.available / area.quantidade_total * 100) + '%' }"></div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- SAÍDA / RETORNO TAB (OPERACIONAL) -->
      <div v-if="currentTab === 'operacao'" class="max-w-4xl mx-auto space-y-6 animate-in slide-in-from-bottom-5 duration-300">
        <div class="bg-white p-8 rounded-3xl border border-slate-200 shadow-sm space-y-8">
           <div class="flex justify-between items-center border-b border-slate-100 pb-6">
              <div>
                <h2 class="text-2xl font-black text-[#113366] flex items-center gap-3">
                  <i class="ph ph-arrows-left-right text-[#ee4d2d]"></i> Movimentação de PDAs
                </h2>
                <p class="text-slate-400 text-sm font-medium">Saídas de estoque para líderes e retornos.</p>
              </div>
              <div class="flex bg-slate-100 p-1 rounded-xl">
                 <button @click="opType = 'saida'" :class="['px-6 py-2 rounded-lg text-xs font-black transition-all', opType === 'saida' ? 'bg-[#113366] text-white shadow-md' : 'text-slate-400 hover:text-slate-600']">SAÍDA</button>
                 <button @click="opType = 'retorno'" :class="['px-6 py-2 rounded-lg text-xs font-black transition-all', opType === 'retorno' ? 'bg-[#ee4d2d] text-white shadow-md' : 'text-slate-400 hover:text-slate-600']">RETORNO</button>
              </div>
           </div>

           <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
              <div class="space-y-4">
                 <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest">Líder Responsável</label>
                 <select v-model="formOp.lider_id" @change="updateLiderMax" class="w-full px-5 py-4 border-2 border-slate-100 rounded-2xl focus:border-[#113366] outline-none font-bold text-[#113366] bg-slate-50">
                    <option value="" disabled>Selecione o Líder...</option>
                    <option v-for="l in lideres" :key="l.id" :value="l.id">
                      {{ l.nome }} ({{ l.areas?.nome }}) - Atual: {{ l.lider_inventory?.[0]?.quantidade || 0 }}
                    </option>
                 </select>
              </div>

              <div class="space-y-4">
                 <div class="flex justify-between items-end">
                    <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest">Quantidade</label>
                    <span v-if="opType === 'retorno' && formOp.lider_id" class="text-[10px] font-bold text-orange-500">Posse atual: {{ currentLiderQty }}</span>
                    <span v-if="opType === 'saida' && formOp.lider_id" class="text-[10px] font-bold text-green-500">Disponível na Área: {{ areaAvailableQty }}</span>
                 </div>
                 <input type="number" v-model="formOp.quantidade" min="1" :max="opMax" class="w-full px-5 py-4 border-2 border-slate-100 rounded-2xl focus:border-[#113366] outline-none font-black text-3xl text-center text-[#113366] bg-slate-50">
              </div>
           </div>

           <div class="space-y-4">
              <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest">Observações (Opcional)</label>
              <textarea v-model="formOp.observacao" rows="2" class="w-full px-5 py-4 border-2 border-slate-100 rounded-2xl focus:border-[#113366] outline-none font-medium text-slate-600 bg-slate-50" placeholder="Motivo da saída/retorno..."></textarea>
           </div>

           <div v-if="!adminUser" class="p-4 bg-red-50 border border-red-100 rounded-xl flex items-center gap-3 text-red-600 animate-pulse">
              <i class="ph-fill ph-warning-circle text-xl"></i>
              <p class="text-xs font-bold">Por favor, selecione sua identificação admin na lateral esquerda para continuar.</p>
           </div>

           <button @click="handleRecordingOp" :disabled="!isOpValid || loading" 
                   :class="['w-full py-5 rounded-2xl font-black shadow-xl transition-all uppercase tracking-widest text-white', 
                           opType === 'saida' ? 'bg-[#113366] shadow-brand-blue/20 hover:scale-[1.01]' : 'bg-[#ee4d2d] shadow-brand-orange/20 hover:scale-[1.01]',
                           (!isOpValid || loading) ? 'opacity-30' : '']">
              Confirmar {{ opType === 'saida' ? 'Saída' : 'Retorno' }} de {{ formOp.quantidade }} PDAs
           </button>
        </div>
      </div>

      <!-- LÍDERES (INVENTÁRIO) TAB -->
      <div v-if="currentTab === 'lideres'" class="space-y-6 max-w-6xl mx-auto animate-in fade-in duration-300">
        <div class="flex justify-between items-center bg-white p-6 rounded-2xl shadow-sm border border-slate-200">
           <div>
              <h2 class="text-3xl font-black text-[#113366] flex items-center gap-2">
                <i class="ph-fill ph-users text-[#ee4d2d]"></i> Inventário por Líder
              </h2>
              <p class="text-slate-400 text-sm font-medium">Visualização de posse por responsável.</p>
           </div>
           <div class="relative group">
              <i class="ph ph-magnifying-glass absolute left-4 top-3.5 text-slate-400 transition-colors group-focus-within:text-[#113366]"></i>
              <input type="text" v-model="filtroLider" placeholder="Buscar líder..." class="pl-12 pr-4 py-3 border-2 border-slate-100 rounded-xl focus:border-[#113366] outline-none text-sm font-bold shadow-sm">
           </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
           <div v-for="l in leadersWithStock" :key="l.id" class="bg-white p-6 rounded-3xl border border-slate-200 shadow-sm hover:shadow-md transition-all flex flex-col items-center text-center">
              <div class="w-16 h-16 bg-slate-50 rounded-2xl flex items-center justify-center text-[#113366] font-black text-2xl border border-slate-100 mb-4 shadow-inner">
                 {{ l.nome.charAt(0) }}
              </div>
              <h4 class="font-black text-[#113366] text-lg leading-tight mb-1">{{ l.nome }}</h4>
              <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-4">{{ l.areas?.nome }}</p>
              
              <div class="bg-indigo-50 text-indigo-700 px-6 py-3 rounded-2xl w-full flex flex-col items-center">
                 <span class="text-[10px] font-black uppercase">Em Posse</span>
                 <span class="text-4xl font-black">{{ l.lider_inventory?.[0]?.quantidade || 0 }}</span>
              </div>
           </div>
        </div>
      </div>

      <!-- TRANSFERÊNCIAS TAB -->
      <div v-if="currentTab === 'transferencias'" class="space-y-6 max-w-5xl mx-auto animate-in slide-in-from-bottom-5 duration-300">
         <div class="bg-white p-8 rounded-3xl border border-slate-200 shadow-sm flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
            <div>
              <h2 class="text-2xl font-black text-[#113366] flex items-center gap-3">
                <i class="ph-fill ph-arrows-merge text-[#ee4d2d]"></i> Autorização de Troca
              </h2>
              <p class="text-slate-400 text-sm font-medium">Aprovação de transferências entre líderes.</p>
            </div>
            <button @click="showNewTransferModal = true" class="bg-[#113366] text-white px-6 py-3 rounded-xl font-bold flex items-center gap-2 shadow-lg hover:scale-105 transition-all text-sm">
               <i class="ph ph-plus-circle text-lg"></i> NOVA TRANSFERÊNCIA
            </button>
         </div>

         <div v-if="pendingTransfers.length" class="grid grid-cols-1 gap-4">
            <div v-for="t in pendingTransfers" :key="t.id" class="bg-white p-6 rounded-3xl border-2 border-orange-100 shadow-sm flex flex-col md:flex-row items-center justify-between gap-6 hover:border-orange-200 transition-all">
               <div class="flex items-center gap-6 flex-1">
                  <div class="flex flex-col items-center">
                     <div class="w-12 h-12 bg-slate-50 rounded-xl flex items-center justify-center font-black text-[#113366] border border-slate-100">{{ t.lider_origem.nome.charAt(0) }}</div>
                     <span class="text-[10px] font-bold text-slate-400 mt-2 truncate max-w-[80px]">{{ t.lider_origem.nome }}</span>
                  </div>
                  <div class="flex-1 flex flex-col items-center gap-1">
                     <div class="h-0.5 w-full bg-slate-100 relative">
                        <div class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 bg-white px-3 py-1 border border-slate-200 rounded-full font-black text-[#ee4d2d] text-lg shadow-sm">
                           {{ t.quantidade }}
                        </div>
                     </div>
                     <span class="text-[9px] font-black text-slate-300 uppercase mt-4">PDAs</span>
                  </div>
                  <div class="flex flex-col items-center">
                     <div class="w-12 h-12 bg-indigo-50 rounded-xl flex items-center justify-center font-black text-indigo-600 border border-indigo-100">{{ t.lider_destino.nome.charAt(0) }}</div>
                     <span class="text-[10px] font-bold text-indigo-400 mt-2 truncate max-w-[80px]">{{ t.lider_destino.nome }}</span>
                  </div>
               </div>
               
               <div v-if="!adminUser" class="text-[10px] font-black text-red-500 uppercase">Selecione Admin para Aprovar</div>
               <div v-else class="flex gap-2">
                  <button @click="handleActionTransfer(t.id, 'REJEITADO')" class="px-5 py-3 rounded-xl bg-slate-100 text-slate-500 font-bold text-xs hover:bg-red-50 hover:text-red-500 transition-all">REJEITAR</button>
                  <button @click="handleActionTransfer(t, 'APROVADO')" class="px-8 py-3 rounded-xl bg-[#113366] text-white font-bold text-xs shadow-lg shadow-brand-blue/20 hover:bg-[#0c2447]">APROVAR</button>
               </div>
            </div>
         </div>
         <div v-else class="text-center py-16 bg-slate-50 border-2 border-dashed border-slate-100 rounded-[40px] text-slate-300 font-black italic">
            Nenhuma transferência pendente de autorização.
         </div>
      </div>

      <!-- PLANEJAMENTO TAB (KEEP EXISTING LOGIC BUT UPDATED) -->
      <div v-if="currentTab === 'planejamento'" class="space-y-6 max-w-7xl mx-auto animate-in slide-in-from-bottom-5 duration-300">
         <div class="bg-white p-8 rounded-[40px] shadow-sm border border-slate-100">
            <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-6 mb-8">
               <div>
                 <h2 class="text-3xl font-black text-[#113366] flex items-center gap-3">
                   <i class="ph-fill ph-calendar-plus text-[#ee4d2d]"></i> Meta do Turno
                 </h2>
                 <p class="text-slate-400 text-sm font-medium">Planejado de PDAs por área e turno.</p>
               </div>
               <div class="flex gap-3 bg-slate-50 p-2 rounded-2xl border border-slate-200">
                  <input type="date" v-model="formPlan.data" class="bg-white border-2 border-slate-200 rounded-xl px-4 py-3 text-sm font-black outline-none focus:border-[#113366]">
                  <select v-model="formPlan.turno" class="bg-white border-2 border-slate-200 rounded-xl px-4 py-3 text-sm font-black outline-none focus:border-[#113366]">
                     <option value="T1">Turno 1</option>
                     <option value="T2">Turno 2</option>
                     <option value="T3">Turno 3</option>
                  </select>
               </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-8">
               <div v-for="area in areas" :key="area.id" class="flex items-center justify-between p-5 bg-slate-50/50 rounded-2xl border border-slate-100 transition-all hover:bg-white hover:border-[#ee4d2d] hover:shadow-sm">
                  <span class="font-black text-[#113366] uppercase text-xs">{{ area.nome }}</span>
                  <input type="number" v-model="formPlan.areas[area.id]" 
                         class="w-24 px-4 py-3 bg-white border-2 border-slate-200 rounded-xl focus:border-[#ee4d2d] outline-none text-center font-black text-lg">
               </div>
            </div>

            <div class="flex justify-end pt-6 border-t border-slate-100">
               <button @click="handleSavePlanning" :disabled="loading" class="bg-[#113366] text-white px-10 py-5 rounded-2xl font-black shadow-2xl hover:scale-105 transition-all flex items-center gap-3 uppercase tracking-widest text-sm">
                  <i class="ph-bold ph-floppy-disk text-xl"></i> Salvar Planejamento
               </button>
            </div>
         </div>
      </div>

      <!-- ON PAGE TAB (REALIZADO VS PLANEJADO) -->
      <div v-if="currentTab === 'onpage'" class="space-y-6 max-w-7xl mx-auto animate-in slide-in-from-bottom-5 duration-300">
         <div class="flex flex-col md:flex-row justify-between items-start md:items-center bg-white p-6 rounded-2xl shadow-sm border border-slate-100 gap-4">
            <div>
              <h2 class="text-3xl font-black text-[#113366] flex items-center gap-2">
                <i class="ph-fill ph-target text-[#ee4d2d]"></i> Realizado vs Planejado
              </h2>
              <p class="text-slate-400 text-sm font-medium">Uso atual em campo vs meta planejada.</p>
            </div>
            <div class="flex gap-2 w-full md:w-auto font-black font-mono text-xs">
              <input type="date" v-model="filtroOnPage.data" class="bg-slate-50 border border-slate-200 rounded-xl px-4 py-2 outline-none focus:border-[#113366]">
              <select v-model="filtroOnPage.turno" class="bg-slate-50 border border-slate-200 rounded-xl px-4 py-2 outline-none focus:border-[#113366]">
                 <option value="T1">T1</option><option value="T2">T2</option><option value="T3">T3</option>
              </select>
            </div>
         </div>

         <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <div v-for="item in onPageList" :key="item.areaId" 
                 class="bg-white p-7 rounded-[40px] border border-slate-100 shadow-sm hover:shadow-xl transition-all relative overflow-hidden group">
               <div class="flex justify-between items-start mb-6">
                 <div>
                    <h4 class="font-black text-[#113366] text-xl uppercase tracking-tight">{{ item.areaNome }}</h4>
                    <p class="text-[10px] font-bold text-slate-300 uppercase tracking-widest">Operação por Turno</p>
                 </div>
                 <div class="bg-blue-50 text-[#113366] p-3 rounded-2xl group-hover:bg-[#ee4d2d] group-hover:text-white transition-colors">
                    <i class="ph-fill ph-users text-2xl"></i>
                 </div>
               </div>

               <div class="space-y-4">
                  <div class="flex justify-between items-end">
                    <div class="flex flex-col">
                       <span class="text-[10px] font-black text-slate-400 uppercase">Em Uso Atual</span>
                       <span class="text-5xl font-black text-[#113366]">{{ item.realizado }}</span>
                    </div>
                    <div class="text-right flex flex-col">
                       <span class="text-[10px] font-black text-slate-400 uppercase">Planejado</span>
                       <span class="text-2xl font-bold" :class="item.planejado ? 'text-slate-300' : 'text-slate-100'">{{ item.planejado || '--' }}</span>
                    </div>
                  </div>

                  <div v-if="item.planejado" class="w-full h-3 bg-slate-100 rounded-full overflow-hidden border border-slate-200 shadow-inner">
                     <div class="h-full transition-all duration-1000 ease-out flex items-center justify-end px-2"
                          :class="item.realizado > item.planejado ? 'bg-red-500' : item.realizado === item.planejado ? 'bg-green-500' : 'bg-brand-orange'"
                          :style="{ width: Math.min((item.realizado / item.planejado) * 100, 100) + '%' }">
                     </div>
                  </div>
               </div>
            </div>
         </div>
      </div>

      <!-- CONFIGURAÇÕES TAB -->
      <div v-if="currentTab === 'config'" class="space-y-6 max-w-7xl mx-auto animate-in fade-in duration-300">
         <div class="bg-white p-6 rounded-2xl shadow-sm border border-slate-200">
           <h2 class="text-3xl font-black text-[#113366] flex items-center gap-2">
             <i class="ph-fill ph-gear text-[#ee4d2d]"></i> Gestão Quantitativa
           </h2>
           <div class="flex gap-4 mt-6">
              <button v-for="st in ['areas', 'lideres']" :key="st" 
                      @click="configSubTab = st"
                      :class="['px-6 py-2 rounded-xl text-xs font-black uppercase tracking-widest transition-all', 
                               configSubTab === st ? 'bg-[#113366] text-white shadow-lg' : 'bg-slate-50 text-slate-400 hover:bg-slate-100']">
                 {{ st === 'areas' ? 'Áreas (Estoque)' : 'Líderes' }}
              </button>
           </div>
         </div>

         <!-- ÁREAS CONFIG (WITH QUANTIDADE TOTAL) -->
         <div v-if="configSubTab === 'areas'" class="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div class="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm h-fit space-y-4">
               <h4 class="font-black text-[#113366] mb-4 uppercase text-xs tracking-widest">Gerenciar Área</h4>
               <div>
                  <label class="text-[9px] font-black text-slate-400 uppercase mb-1 block">Nome da Área</label>
                  <input type="text" v-model="formNewArea.nome" placeholder="Ex: Recebimento" class="w-full px-4 py-3 border-2 border-slate-100 rounded-xl focus:border-[#ee4d2d] outline-none font-bold text-sm">
               </div>
               <div>
                  <label class="text-[9px] font-black text-slate-400 uppercase mb-1 block">Capacidade Total de PDAs</label>
                  <input type="number" v-model="formNewArea.quantidade_total" class="w-full px-4 py-3 border-2 border-slate-100 rounded-xl focus:border-[#ee4d2d] outline-none font-black text-lg">
               </div>
               <button @click="handleAddArea" :disabled="!formNewArea.nome || loading"
                       class="w-full bg-[#113366] text-white py-3 rounded-xl font-black text-xs hover:bg-[#0c2447] disabled:opacity-30">
                  SALVAR / CADASTRAR ÁREA
               </button>
            </div>
            <div class="md:col-span-2 bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden text-sm">
               <table class="w-full text-left">
                  <thead class="bg-slate-50 border-b border-slate-100">
                     <tr>
                        <th class="px-6 py-4 font-black text-slate-400 uppercase tracking-widest">Área</th>
                        <th class="px-6 py-4 font-black text-slate-400 uppercase tracking-widest text-center">Capacidade Total</th>
                        <th class="px-6 py-4 text-right">Ação</th>
                     </tr>
                  </thead>
                  <tbody class="divide-y divide-slate-50">
                     <tr v-for="a in areas" :key="a.id" class="hover:bg-slate-50/50">
                        <td class="px-6 py-4 font-bold text-[#113366] uppercase">{{ a.nome }}</td>
                        <td class="px-6 py-4 font-black text-center text-lg">{{ a.quantidade_total }}</td>
                        <td class="px-6 py-4 text-right">
                           <button @click="handleEditArea(a)" class="text-slate-300 hover:text-blue-500 mr-3"><i class="ph-bold ph-pencil"></i></button>
                           <button @click="handleDeleteArea(a.id)" class="text-slate-300 hover:text-red-500 transition-colors"><i class="ph-bold ph-trash"></i></button>
                        </td>
                     </tr>
                  </tbody>
               </table>
            </div>
         </div>

         <!-- LÍDERES CONFIG (KEEP EXISTING) -->
         <div v-if="configSubTab === 'lideres'" class="grid grid-cols-1 md:grid-cols-4 gap-6 text-sm">
            <div class="md:col-span-1 bg-white p-6 rounded-2xl border border-slate-200 shadow-sm h-fit space-y-4">
               <h4 class="font-black text-[#113366] mb-4 uppercase text-xs tracking-widest">Novo Líder</h4>
               <div>
                  <label class="text-[9px] font-black text-slate-400 uppercase mb-1 block">Nome Completo</label>
                  <input type="text" v-model="formNewLider.nome" class="w-full px-4 py-2 border-2 border-slate-100 rounded-lg focus:border-[#ee4d2d] outline-none font-bold text-sm">
               </div>
               <div>
                  <label class="text-[9px] font-black text-slate-400 uppercase mb-1 block">Área Fixa</label>
                  <select v-model="formNewLider.area_id" class="w-full px-4 py-2 border-2 border-slate-100 rounded-lg focus:border-[#ee4d2d] outline-none font-bold text-sm">
                     <option v-for="a in areas" :key="a.id" :value="a.id">{{ a.nome }}</option>
                  </select>
               </div>
               <button @click="handleAddLider" :disabled="!formNewLider.nome || !formNewLider.area_id || loading"
                       class="w-full bg-[#113366] text-white py-3 rounded-xl font-black text-xs hover:bg-[#0c2447] disabled:opacity-30">
                  CADASTRAR LÍDER
               </button>
            </div>
            <div class="md:col-span-3 bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
               <table class="w-full text-left">
                  <thead class="bg-slate-50 border-b border-slate-100">
                     <tr>
                        <th class="px-6 py-4 font-black text-slate-400 uppercase tracking-widest">Líder</th>
                        <th class="px-6 py-4 font-black text-slate-400 uppercase tracking-widest text-center">Área Vinculada</th>
                        <th class="px-6 py-4 text-right">Ação</th>
                     </tr>
                  </thead>
                  <tbody class="divide-y divide-slate-50">
                     <tr v-for="l in lideres" :key="l.id" class="hover:bg-slate-50/50">
                        <td class="px-6 py-4 font-bold text-[#113366]">{{ l.nome }}</td>
                        <td class="px-6 py-4 uppercase font-bold text-slate-400 text-center">{{ l.areas?.nome || 'Sem Área' }}</td>
                        <td class="px-6 py-4 text-right">
                           <button @click="handleDeleteLider(l.id)" class="text-slate-300 hover:text-red-500 transition-colors"><i class="ph-bold ph-trash"></i></button>
                        </td>
                     </tr>
                  </tbody>
               </table>
            </div>
         </div>
      </div>

      <!-- NEW TRANSFER MODAL -->
      <div v-if="showNewTransferModal" class="fixed inset-0 bg-[#113366]/90 backdrop-blur-md z-[210] flex items-center justify-center p-4">
         <div class="bg-white rounded-[40px] shadow-2xl w-full max-w-lg overflow-hidden animate-in zoom-in-95 duration-200 p-8 space-y-6">
            <div class="flex justify-between items-center">
               <h3 class="text-2xl font-black text-[#113366]">Nova Transferência</h3>
               <button @click="showNewTransferModal = false" class="text-slate-300 hover:text-red-500"><i class="ph-bold ph-x text-2xl"></i></button>
            </div>
            
            <div class="space-y-4">
               <div>
                  <label class="text-[10px] font-black text-slate-400 uppercase block mb-1">Origem (De)</label>
                  <select v-model="formTransfer.origem_id" class="w-full px-4 py-3 border-2 border-slate-100 rounded-xl font-bold bg-slate-50">
                     <option value="" disabled>Selecione Líder de Origem</option>
                     <option v-for="l in lideres" :key="l.id" :value="l.id">{{ l.nome }} ({{ l.lider_inventory?.[0]?.quantidade || 0 }})</option>
                  </select>
               </div>
               <div>
                  <label class="text-[10px] font-black text-slate-400 uppercase block mb-1">Destino (Para)</label>
                  <select v-model="formTransfer.destino_id" class="w-full px-4 py-3 border-2 border-slate-100 rounded-xl font-bold bg-slate-50">
                     <option value="" disabled>Selecione Líder de Destino</option>
                     <option v-for="l in otherLideresForTransfer" :key="l.id" :value="l.id">{{ l.nome }}</option>
                  </select>
               </div>
               <div>
                  <label class="text-[10px] font-black text-slate-400 uppercase block mb-1">Quantidade</label>
                  <input type="number" v-model="formTransfer.quantidade" class="w-full px-4 py-3 border-2 border-slate-100 rounded-xl font-black text-2xl text-center bg-slate-50">
               </div>
            </div>

            <button @click="handleCreateTransfer" :disabled="!isTransferValid || loading" class="w-full bg-[#113366] text-white py-5 rounded-2xl font-black shadow-xl disabled:opacity-30 uppercase tracking-widest text-sm">
               REGISTRAR TRANSFERÊNCIA
            </button>
         </div>
      </div>

    </main>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import { supabase } from '../lib/supabase';
import { getInfoOperacional } from '../utils/shiftLogic';

// Identificação
const adminUser = ref(localStorage.getItem('admin_id') || '');
const admins = ['WFM Coord', 'Admin 01', 'Admin 02', 'Liderança Noite'];
watch(adminUser, (val) => localStorage.setItem('admin_id', val));

// State
const currentTab = ref(localStorage.getItem('admin_tab_v4') || 'dash');
watch(currentTab, (val) => localStorage.setItem('admin_tab_v4', val));

const loading = ref(true);
const toasts = ref([]);
const areas = ref([]);
const lideres = ref([]);
const pendingTransfers = ref([]);
const planejamento = ref([]);
const currentTabHistory = ref([]); // Movimentações

// Filters
const filtroLider = ref('');
const filtroOnPage = ref({ data: '', turno: '' });

// Forms
const opType = ref('saida');
const formOp = ref({ lider_id: '', quantidade: 1, observacao: '' });
const formPlan = ref({ data: '', turno: 'T1', areas: {} });
const formNewArea = ref({ id: null, nome: '', quantidade_total: 0 });
const formNewLider = ref({ nome: '', area_id: '' });
const showNewTransferModal = ref(false);
const formTransfer = ref({ origem_id: '', destino_id: '', quantidade: 1 });

const tabs = [
  { id: 'dash', label: 'Dashboard', icon: 'ph-squares-four' },
  { id: 'operacao', label: 'Saída/Retorno', icon: 'ph-arrows-left-right' },
  { id: 'lideres', label: 'Líderes', icon: 'ph-users' },
  { id: 'transferencias', label: 'Transferências', icon: 'ph-arrows-merge' },
  { id: 'planejamento', label: 'Planejamento', icon: 'ph-calendar-plus' },
  { id: 'onpage', label: 'On Page', icon: 'ph-presentation-chart' }
];

// Computed
const navClass = (id) => `w-full flex items-center gap-3 px-4 py-3 rounded-xl transition-all font-bold text-sm ${currentTab.value === id ? 'bg-[#ee4d2d] text-white shadow-xl translate-x-1' : 'text-slate-400 hover:text-white hover:bg-white/5'}`;

const pendingTransfersCount = computed(() => pendingTransfers.value.length);

const inventoryByArea = computed(() => {
  return areas.value.map(area => {
    // In Use: soma das quantidades de PDAs com líderes desta área
    const inUse = lideres.value
      .filter(l => l.area_id === area.id)
      .reduce((sum, l) => sum + (l.lider_inventory?.[0]?.quantidade || 0), 0);
    
    return {
      ...area,
      inUse,
      available: Math.max(0, area.quantidade_total - inUse)
    };
  });
});

const kpis = computed(() => {
  const totalPool = areas.value.reduce((sum, a) => sum + a.quantidade_total, 0);
  const totalInUse = lideres.value.reduce((sum, l) => sum + (l.lider_inventory?.[0]?.quantidade || 0), 0);
  return {
    total: totalPool,
    disponiveis: totalPool - totalInUse,
    comLideres: totalInUse,
    areas: areas.value.length
  };
});

const kpiCards = computed(() => [
  { label: 'Total Geral Pool', value: kpis.value.total, icon: 'ph-fill ph-package', iconBg: 'bg-blue-50', iconColor: 'text-[#113366]' },
  { label: 'Disponível Estoque', value: kpis.value.disponiveis, icon: 'ph-fill ph-check-circle', iconBg: 'bg-green-50', iconColor: 'text-green-600' },
  { label: 'Em Campo (Líderes)', value: kpis.value.comLideres, icon: 'ph-fill ph-users', iconBg: 'bg-orange-50', iconColor: 'text-orange-500' },
  { label: 'Áreas Ativas', value: kpis.value.areas, icon: 'ph-fill ph-factory', iconBg: 'bg-indigo-50', iconColor: 'text-indigo-600' },
]);

const leadersWithStock = computed(() => {
  return lideres.value
    .filter(l => l.nome.toLowerCase().includes(filtroLider.value.toLowerCase()))
    .sort((a, b) => (b.lider_inventory?.[0]?.quantidade || 0) - (a.lider_inventory?.[0]?.quantidade || 0));
});

const currentLiderQty = computed(() => {
   const l = lideres.value.find(lid => lid.id === formOp.value.lider_id);
   return l?.lider_inventory?.[0]?.quantidade || 0;
});

const areaAvailableQty = computed(() => {
   const l = lideres.value.find(lid => lid.id === formOp.value.lider_id);
   if (!l) return 0;
   const area = inventoryByArea.value.find(a => a.id === l.area_id);
   return area?.available || 0;
});

const opMax = computed(() => opType.value === 'saida' ? areaAvailableQty.value : currentLiderQty.value);

const isOpValid = computed(() => {
   return adminUser.value && 
          formOp.value.lider_id && 
          formOp.value.quantidade > 0 && 
          formOp.value.quantidade <= opMax.value;
});

const otherLideresForTransfer = computed(() => lideres.value.filter(l => l.id !== formTransfer.value.origem_id));
const isTransferValid = computed(() => {
   const sourceQty = lideres.value.find(l => l.id === formTransfer.value.origem_id)?.lider_inventory?.[0]?.quantidade || 0;
   return formTransfer.value.origem_id && 
          formTransfer.value.destino_id && 
          formTransfer.value.quantidade > 0 && 
          formTransfer.value.quantidade <= sourceQty;
});

const onPageList = computed(() => {
  if (!filtroOnPage.value.data || !filtroOnPage.value.turno) return [];
  return areas.value.map(area => {
    const plan = planejamento.value.find(p => p.area_id === area.id && p.data === filtroOnPage.value.data && p.turno === filtroOnPage.value.turno);
    const areaInventory = inventoryByArea.value.find(a => a.id === area.id);
    return {
      areaId: area.id,
      areaNome: area.nome,
      realizado: areaInventory?.inUse || 0,
      planejado: plan ? plan.quantidade : 0
    };
  }).filter(a => a.planejado > 0 || a.realizado > 0);
});

// Methods
const showMessage = (msg, tipo = 'sucesso') => {
  const id = Date.now();
  toasts.value.push({ id, mensagem: msg, tipo });
  setTimeout(() => toasts.value = toasts.value.filter(t => t.id !== id), 5000);
};

const fetchInitialData = async () => {
  loading.value = true;
  try {
    const { data: areasData } = await supabase.from('areas').select('*').order('nome');
    areas.value = areasData || [];

    const { data: leadersData } = await supabase.from('lideres').select('*, areas(nome), lider_inventory(quantidade)');
    lideres.value = leadersData || [];

    const { data: transfersData } = await supabase.from('trocas_pendentes').select('*, lider_origem:lideres!lider_origem_id(nome), lider_destino:lideres!lider_destino_id(nome)').eq('status', 'PENDENTE');
    pendingTransfers.value = transfersData || [];

    const { data: planData } = await supabase.from('planejamento').select('*');
    planejamento.value = planData || [];

    const op = getInfoOperacional();
    if (!filtroOnPage.value.data) {
      filtroOnPage.value.data = op.dataOperacional;
      filtroOnPage.value.turno = op.turno;
    }
  } catch (e) {
    showMessage(e.message, 'erro');
  } finally {
    loading.value = false;
  }
};

const handleRecordingOp = async () => {
  loading.value = true;
  try {
    const { lider_id, quantidade, observacao } = formOp.value;
    const typeLabel = opType.value === 'saida' ? 'Saída' : 'Retorno';
    
    // 1. Update Leader Inventory
    const currentQty = lideres.value.find(l => l.id === lider_id)?.lider_inventory?.[0]?.quantidade || 0;
    const newQty = opType.value === 'saida' ? currentQty + quantidade : currentQty - quantidade;
    
    const { error: invError } = await supabase.from('lider_inventory').upsert({ lider_id, quantidade: newQty, last_updated: new Date() }, { onConflict: 'lider_id' });
    if (invError) throw invError;

    // 2. Record Movement
    const { error: movError } = await supabase.from('movimentacoes').insert({
      lider_id,
      tipo: typeLabel,
      quantidade,
      admin_id: adminUser.value,
      observacao
    });
    if (movError) throw movError;

    showMessage(`${typeLabel} de ${quantidade} PDAs registrada com sucesso!`);
    formOp.value = { lider_id: '', quantidade: 1, observacao: '' };
    await fetchInitialData();
  } catch (e) {
    showMessage(e.message, 'erro');
  } finally {
    loading.value = false;
  }
};

const handleCreateTransfer = async () => {
   loading.value = true;
   try {
      const { error } = await supabase.from('trocas_pendentes').insert({
         lider_origem_id: formTransfer.value.origem_id,
         lider_destino_id: formTransfer.value.destino_id,
         quantidade: formTransfer.value.quantidade,
         status: 'PENDENTE'
      });
      if (error) throw error;
      
      showNewTransferModal.value = false;
      formTransfer.value = { origem_id: '', destino_id: '', quantidade: 1 };
      await fetchInitialData();
      showMessage('Transferência solicitada! Aguardando aprovação admin.');
   } catch (e) {
      showMessage(e.message, 'erro');
   } finally {
      loading.value = false;
   }
};

const handleActionTransfer = async (transfer, status) => {
   loading.value = true;
   try {
      if (status === 'APROVADO') {
         // Perform standard quantity swap
         const origId = transfer.lider_origem_id;
         const destId = transfer.lider_destino_id;
         const qty = transfer.quantidade;

         const origQty = lideres.value.find(l => l.id === origId)?.lider_inventory?.[0]?.quantidade || 0;
         const destQty = lideres.value.find(l => l.id === destId)?.lider_inventory?.[0]?.quantidade || 0;

         // Atomic updates not strictly possible without Rpc, but we'll sequential for simplicity in this demo
         await supabase.from('lider_inventory').upsert({ lider_id: origId, quantidade: origQty - qty, last_updated: new Date() });
         await supabase.from('lider_inventory').upsert({ lider_id: destId, quantidade: destQty + qty, last_updated: new Date() });

         // Log Movements
         await supabase.from('movimentacoes').insert([
            { lider_id: origId, tipo: 'Transferência-Enviada', quantidade: qty, admin_id: adminUser.value, origem_destino_id: destId },
            { lider_id: destId, tipo: 'Transferência-Recebida', quantidade: qty, admin_id: adminUser.value, origem_destino_id: origId }
         ]);
      }

      await supabase.from('trocas_pendentes').update({ status, admin_id: adminUser.value }).eq('id', typeof transfer === 'string' ? transfer : transfer.id);
      
      showMessage(`Transferência ${status.toLowerCase()}!`);
      await fetchInitialData();
   } catch (e) {
      showMessage(e.message, 'erro');
   } finally {
      loading.value = false;
   }
};

const handleSavePlanning = async () => {
    loading.value = true;
    try {
        const payload = Object.entries(formPlan.value.areas).map(([areaId, qty]) => ({
            data: formPlan.value.data,
            turno: formPlan.value.turno,
            area_id: areaId,
            quantidade: qty
        }));
        const { error } = await supabase.from('planejamento').upsert(payload, { onConflict: 'data, turno, area_id' });
        if (error) throw error;
        showMessage('Planejamento salvo!');
        await fetchInitialData();
    } catch (e) { showMessage(e.message, 'erro'); }
    finally { loading.value = false; }
};

const handleAddArea = async () => {
  loading.value = true;
  try {
    const { error } = await supabase.from('areas').upsert({ 
      id: formNewArea.value.id || undefined,
      nome: formNewArea.value.nome, 
      quantidade_total: formNewArea.value.quantidade_total 
    });
    if (error) throw error;
    showMessage('Área salva!');
    formNewArea.value = { id: null, nome: '', quantidade_total: 0 };
    await fetchInitialData();
  } catch (e) { showMessage(e.message, 'erro'); }
  finally { loading.value = false; }
};

const handleEditArea = (area) => {
  formNewArea.value = { ...area };
};

const handleDeleteArea = async (id) => {
  if (!confirm('Excluir esta área?')) return;
  loading.value = true;
  try {
    await supabase.from('areas').delete().eq('id', id);
    showMessage('Área excluída.');
    await fetchInitialData();
  } catch (e) { showMessage(e.message, 'erro'); }
  finally { loading.value = false; }
};

const handleAddLider = async () => {
    loading.value = true;
    try {
        const { data: lid, error } = await supabase.from('lideres').insert({ 
            nome: formNewLider.value.nome, 
            area_id: formNewLider.value.area_id 
        }).select().single();
        if (error) throw error;
        
        // Initialize inventory
        await supabase.from('lider_inventory').insert({ lider_id: lid.id, quantidade: 0 });

        showMessage('Líder cadastrado!');
        formNewLider.value = { nome: '', area_id: '' };
        await fetchInitialData();
    } catch (e) { showMessage(e.message, 'erro'); }
    finally { loading.value = false; }
};

const handleDeleteLider = async (id) => {
    if (!confirm('Excluir este líder?')) return;
    loading.value = true;
    try {
        await supabase.from('lideres').delete().eq('id', id);
        showMessage('Líder excluído.');
        await fetchInitialData();
    } catch (e) { showMessage(e.message, 'erro'); }
    finally { loading.value = false; }
};

// Subscriptions
let channel;
onMounted(() => {
  fetchInitialData();
  channel = supabase.channel('quantity-updates')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'lider_inventory' }, () => fetchInitialData())
    .on('postgres_changes', { event: '*', schema: 'public', table: 'trocas_pendentes' }, () => fetchInitialData())
    .on('postgres_changes', { event: '*', schema: 'public', table: 'planejamento' }, () => fetchInitialData())
    .on('postgres_changes', { event: '*', schema: 'public', table: 'areas' }, () => fetchInitialData())
    .subscribe();
});

onUnmounted(() => {
  if (channel) supabase.removeChannel(channel);
});
</script>

<style scoped>
.shadow-brand-blue/20 { shadow-color: rgba(17, 51, 102, 0.2); }
.shadow-brand-orange/20 { shadow-color: rgba(238, 77, 45, 0.2); }
</style>
