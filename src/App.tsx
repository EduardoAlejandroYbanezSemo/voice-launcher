import { useState, useEffect } from 'react';
import { listen, emit } from '@tauri-apps/api/event';
import { convertFileSrc } from '@tauri-apps/api/core';
import './App.css';
import { 
  MicIcon, 
  GamepadIcon, 
  CheckIcon, 
  ErrorIcon, 
  RocketIcon, 
  InfoIcon,
  ClockIcon
} from './components/Icons';

// Tipos
interface Game {
  id: string;
  name: string;
  cmd: string;
  image?: string;
}

type LogType = 'success' | 'error' | 'launch' | 'info' | 'time';

interface LogEntry {
  type: LogType;
  text: string;
  id: number; // Para key única
}

const HINTS = [
  "Di 'Listar juegos' para ver tu colección",
  "Di 'Abrir Pokemon' para jugar",
  "Di 'Apagar consola' para salir",
  "Di 'Catálogo'..."
];

function App() {
  const [status, setStatus] = useState<"booting" | "ready" | "listening">("booting");
  const [logs, setLogs] = useState<LogEntry[]>([]);
  const [view, setView] = useState<"welcome" | "library">("welcome");
  const [hintIndex, setHintIndex] = useState(0);
  const [games, setGames] = useState<Game[]>([]);

  useEffect(() => {
    emit("request-games");

    const interval = setInterval(() => {
      setHintIndex(prev => (prev + 1) % HINTS.length);
    }, 5000);

    let timeout: number;
    if (view === 'library') {
      timeout = setTimeout(() => {
        setView('welcome');
        addLog('info', "Volviendo al inicio...");
      }, 15000);
    }

    const unlistenStatus = listen('voice-status', (event: any) => setStatus(event.payload));
    
    // --- LISTENERS MODIFICADOS PARA USAR TIPOS ---
    const unlistenCmd = listen('command-executed', (event: any) => {
      const message = event.payload as string;
      // Detectar si es un mensaje de hora
      if (message.includes('Son las')) {
        addLog('time', message);
      } else {
        addLog('success', message);
      }
      setStatus("ready");
    });

    const unlistenErr = listen('command-error', (event: any) => {
      addLog('error', event.payload);
      setStatus("ready");
    });

    const unlistenLib = listen('show-library', () => {
      setView('library');
      addLog('info', "Abriendo biblioteca...");
    });

    const unlistenGames = listen('games-list', (event: any) => {
      setGames(event.payload as Game[]);
    });

    const unlistenLaunch = listen('game-launch', (e: any) => {
      addLog('launch', `Lanzando: ${e.payload}`);
    });

    const unlistenTime = listen('time-info', () => {
      // El log ya se agrega desde command-executed con el texto de respuesta
    });

    return () => {
      clearInterval(interval);
      clearTimeout(timeout);
      unlistenStatus.then(f => f());
      unlistenCmd.then(f => f());
      unlistenErr.then(f => f());
      unlistenLib.then(f => f());
      unlistenGames.then(f => f());
      unlistenLaunch.then(f => f());
      unlistenTime.then(f => f());
    };
  }, [view]);

  const addLog = (type: LogType, text: string) => {
    setLogs(prev => [{ type, text, id: Date.now() }, ...prev].slice(0, 8));
  };

  const getImageUrl = (path?: string) => {
    if (!path) return undefined;
    if (path.startsWith('http')) return path;
    if (path.startsWith('/')) return path; 
    return convertFileSrc(path);
  };

  return (
    <div className="app-container">
      {/* SIDEBAR */}
      <aside className="sidebar">
        <div>
          <div className="mic-section">
            <div className={`mic-wrapper ${status === 'listening' ? 'listening' : ''}`}>
              <MicIcon active={status === 'listening'} />
            </div>
            <div className="status-label">
              {status === 'booting' && "INICIANDO..."}
              {status === 'ready' && "ESPERANDO COMANDO"}
              {status === 'listening' && "ESCUCHANDO..."}
            </div>
          </div>
        </div>

        <div className="history-section">
          <div className="history-title">Registro de Actividad</div>
          {logs.length === 0 && <div className="log-item" style={{opacity:0.3}}>Esperando órdenes...</div>}
          
          {logs.map((log) => (
            <div key={log.id} className="log-item">
              <div className="log-icon">
                {log.type === 'success' && <CheckIcon />}
                {log.type === 'error' && <ErrorIcon />}
                {log.type === 'launch' && <RocketIcon />}
                {log.type === 'info' && <InfoIcon />}
                {log.type === 'time' && <ClockIcon />}
              </div>
              <span>{log.text}</span>
            </div>
          ))}
        </div>
      </aside>

      {/* STAGE */}
      <main className="stage">
        {view === 'welcome' && (
          <div className="welcome-container">
            <h1 className="hint-title">Bienvenido</h1>
            <p className="hint-text">"{HINTS[hintIndex]}"</p>
          </div>
        )}

        {view === 'library' && (
          <div className="library-grid">
            {games.length === 0 && <p style={{color:'#666'}}>No hay juegos en games.json</p>}
            
            {games.map(game => {
              const bgUrl = getImageUrl(game.image);
              return (
                <div 
                  key={game.id} 
                  className="game-card" 
                  onClick={() => addLog('launch', `Seleccionado: ${game.name}`)}
                  style={
                    bgUrl 
                      ? { 
                          backgroundImage: `url(${bgUrl})`,
                          backgroundSize: 'cover',
                          backgroundPosition: 'center'
                        } 
                      : {}
                  }
                >
                  {!bgUrl && <GamepadIcon />}
                  <div className="game-info-overlay">
                    <div className="game-title">{game.name}</div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </main>
    </div>
  );
}

export default App;
