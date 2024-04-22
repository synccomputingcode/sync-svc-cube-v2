import { createTheme } from "@mui/material";

declare module "@mui/material/styles" {
  interface Palette {
    gradient: Palette["background"];
  }
  interface PaletteOptions {
    gradient?: PaletteOptions["background"];
  }
}
export const theme = createTheme({
  palette: {
    mode: "dark",
    primary: {
      main: "#926fc9",
    },
    background: {
      default: "#121212",
      paper: "#1e1b22",
    },
    gradient: {
      default:
        "linear-gradient(to right top, rgb(56, 67, 139), rgb(148, 75, 148), rgb(215, 90, 136), rgb(255, 126, 113), rgb(255, 178, 95), rgb(255, 235, 104))",
    },
  },
  components: {
    MuiButton: {
      defaultProps: {
        variant: "contained",
      },
    },
  },
});
