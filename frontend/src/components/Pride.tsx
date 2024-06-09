import { Box, Paper, styled } from "@mui/material";
import { useMemo, useState } from "react";

const RainbowSpan = styled("td")({
  animationName: "rainbow",
  animationDuration: "30s",
  animationDirection: "normal",
  animationIterationCount: "infinite",
  animationTimingFunction: "linear",
  color: "transparent",
  "@keyframes rainbow": {
    "0%,9%": {
      color: "rgb(228, 3, 3)",
    },
    "10%,19%": { color: "transparent" },
    "20%,29%": {
      color: "rgb(255, 140, 0)",
    },
    "30%,39%": { color: "transparent" },
    "40%,49%": {
      color: "rgb(255, 237, 0)",
    },
    "50%,59%": { color: "transparent" },
    "60%,69%": {
      color: "rgb(0, 128, 38)",
    },
    "70%,79%": { color: "transparent" },
    "80%,89%": {
      color: "rgb(36, 64, 142)",
    },
    "90%,99%": { color: "transparent" },
    "100%,109%": {
      color: "rgb(115, 41, 130)",
    },
    "110%": {
      color: "transparent",
    },
  },
});
type SkyBoxProps = {
  children?: React.ReactNode;
};

const characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".toLowerCase();

export const Pride = ({ children }: SkyBoxProps) => {
  const [hiddenCharRef, setHiddenCharRef] = useState<HTMLDivElement | null>(
    null,
  );
  const [paperRef, setPaperRef] = useState<HTMLDivElement | null>(null);
  const [columns, rows] = useMemo(() => {
    if (!hiddenCharRef || !paperRef) {
      return [0, 0];
    }
    const fontSize = getComputedStyle(hiddenCharRef);
    console.log(
      paperRef?.clientWidth,
      paperRef?.clientHeight,
      parseInt(fontSize.width),
      parseInt(fontSize.height),
    );

    const columns = Math.floor(paperRef.clientWidth / parseInt(fontSize.width));
    const rows = Math.floor(paperRef.clientHeight / parseInt(fontSize.height));
    return [columns, rows];
  }, [hiddenCharRef, paperRef]);
  console.log("columns", columns, "rows", rows);
  return (
    <>
      <Box
        ref={setHiddenCharRef}
        sx={{
          visibility: "hidden",
          position: "absolute",
          top: "-9999px",
          left: "-9999px",
        }}
      >
        9
      </Box>
      <Paper
        ref={setPaperRef}
        sx={{
          minHeight: "100dvh",
          backgroundColor: "transparent",
        }}
      >
        <Box
          id="rainbow"
          component="table"
          sx={{
            position: "absolute",
            top: 0,
            tableLayout: "fixed",
            left: 0,
            width: paperRef?.clientWidth || 0,
            height: paperRef?.clientHeight || 0,
            backgroundRepeat: "no-repeat",
            backgroundColor: "black",
            zIndex: -2,
          }}
        >
          {Array.from({ length: rows }).map((_, x) => (
            <tr key={`row-${x}`} style={{ overflow: "hidden" }}>
              {Array.from({ length: columns }).map((_, y) => (
                <RainbowSpan
                  key={`col-${y}`}
                  style={{
                    paddingLeft: 0.1,
                    paddingRight: 0.1,
                    animationDelay: `${Math.floor(Math.random() * y) * 10}ms`,
                  }}
                >
                  {characters[Math.floor(Math.random() * characters.length)]}
                </RainbowSpan>
              ))}
            </tr>
          ))}
        </Box>
        {children}
      </Paper>
    </>
  );
};
