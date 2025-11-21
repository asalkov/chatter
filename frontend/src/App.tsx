import { Container, Box, Typography, Button, Paper } from '@mui/material';
import ChatIcon from '@mui/icons-material/Chat';

function App() {
  return (
    <Container maxWidth="md">
      <Box
        sx={{
          minHeight: '100vh',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          alignItems: 'center',
          gap: 3,
        }}
      >
        <Paper
          elevation={3}
          sx={{
            p: 4,
            textAlign: 'center',
            borderRadius: 2,
          }}
        >
          <ChatIcon sx={{ fontSize: 60, color: 'primary.main', mb: 2 }} />
          <Typography variant="h3" component="h1" gutterBottom>
            Chatter
          </Typography>
          <Typography variant="h6" color="text.secondary" gutterBottom>
            Real-time Chat Application
          </Typography>
          <Typography variant="body1" color="text.secondary" sx={{ mt: 2, mb: 3 }}>
            Frontend is successfully set up with React, TypeScript, Vite, and Material UI!
          </Typography>
          <Box sx={{ display: 'flex', gap: 2, justifyContent: 'center' }}>
            <Button variant="contained" size="large">
              Get Started
            </Button>
            <Button variant="outlined" size="large">
              Learn More
            </Button>
          </Box>
        </Paper>
        
        <Paper sx={{ p: 2, width: '100%' }}>
          <Typography variant="subtitle2" color="text.secondary">
            Tech Stack:
          </Typography>
          <Typography variant="body2" sx={{ mt: 1 }}>
            ⚛️ React 19 • 📘 TypeScript • ⚡ Vite • 🎨 Material UI • 🔄 Redux Toolkit • 🌐 Socket.IO
          </Typography>
        </Paper>
      </Box>
    </Container>
  );
}

export default App;
