import { Container } from "@mui/material";
import underConstruction from "./assets/under-construction.gif";

function App() {
  return (
    <Container maxWidth={"sm"}>
      <img src={underConstruction} alt="Under Construction" width="100%" />
    </Container>
  );
}

export default App;
