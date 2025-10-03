import React, { useState, useEffect } from 'react'
import Dashboard from './components/Dashboard'
import WalletManager from './components/WalletManager'
import NodeStatus from './components/NodeStatus'
import PriceChart from './components/PriceChart'
import { ApiService } from './services/api'

function App() {
  const [activeTab, setActiveTab] = useState('dashboard')
  const [systemStatus, setSystemStatus] = useState(null)

  useEffect(() => {
    const checkSystem = async () => {
      try {
        const status = await ApiService.getSystemInfo()
        setSystemStatus(status)
      } catch (error) {
        console.error('Erreur système:', error)
      }
    }
    
    checkSystem()
    const interval = setInterval(checkSystem, 30000) // Check toutes les 30s
    
    return () => clearInterval(interval)
  }, [])

  const tabs = [
    { id: 'dashboard', label: 'Dashboard', icon: '📊' },
    { id: 'wallet', label: 'Wallets', icon: '💰' },
    { id: 'node', label: 'Nœud Kaspa', icon: '🔗' },
    { id: 'prices', label: 'Prix', icon: '📈' }
  ]

  return (
    <div className="min-h-screen bg-gray-100">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <div className="flex items-center">
              <h1 className="text-2xl font-bold text-gray-900">KaspaZof</h1>
              <span className="ml-2 text-sm text-gray-500">v0.1.0</span>
            </div>
            
            {/* Status système */}
            <div className="flex items-center space-x-2">
              <div className={`w-3 h-3 rounded-full ${
                systemStatus?.services?.postgres ? 'bg-green-500' : 'bg-red-500'
              }`} title="Base de données"></div>
              <div className={`w-3 h-3 rounded-full ${
                systemStatus?.services?.redis ? 'bg-green-500' : 'bg-yellow-500'
              }`} title="Cache Redis"></div>
              <div className={`w-3 h-3 rounded-full ${
                systemStatus?.services?.kaspa_node ? 'bg-green-500' : 'bg-red-500'
              }`} title="Nœud Kaspa"></div>
            </div>
          </div>
        </div>
      </header>

      {/* Navigation */}
      <nav className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex space-x-8">
            {tabs.map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`py-4 px-1 border-b-2 font-medium text-sm ${
                  activeTab === tab.id
                    ? 'border-blue-500 text-blue-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                <span className="mr-2">{tab.icon}</span>
                {tab.label}
              </button>
            ))}
          </div>
        </div>
      </nav>

      {/* Contenu principal */}
      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div className="px-4 py-6 sm:px-0">
          {activeTab === 'dashboard' && <Dashboard />}
          {activeTab === 'wallet' && <WalletManager />}
          {activeTab === 'node' && <NodeStatus />}
          {activeTab === 'prices' && <PriceChart />}
        </div>
      </main>
    </div>
  )
}

export default App