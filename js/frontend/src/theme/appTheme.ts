import {createTheme, Theme} from "@mui/material/styles";
import {blue, indigo, green, lightGreen, pink, purple, deepOrange, orange} from '@mui/material/colors';
import {RuntimeSettings} from "../config/runtimeConfig";

// define light theme colors
export const lightTheme: Theme = createTheme({
    palette: {
        mode: "light",
        text: {
            primary: "#000000",
            secondary: "#262626"
        },
        primary: {
            main: "#0a67b1",
        },
        background: {
            default: "#fafafa",
        },
    },
});

// define dark theme colors
export const darkTheme: Theme = createTheme({
    palette: {
        mode: "dark",
        text: {
            primary: "#ffffff",
            secondary: "#afafaf",
        },
        primary: {
            main: "#07121a",
        },
        background: {
            default: "#112e44",
        },
    },
});

// general colour themes
export function createdColouredThemes(settings: RuntimeSettings): { [key: string]: Theme; }  {
    return {
        "blue": createTheme({
            palette: {
                primary: indigo,
                secondary: blue,
            },
        }),
        "green": createTheme({
            palette: {
                primary: green,
                secondary: lightGreen,
            },
        }),
        "pink": createTheme({
            palette: {
                primary: pink,
                secondary: purple,
            },
        }),
        "orange": createTheme({
            palette: {
                primary: deepOrange,
                secondary: orange,
            },
        }),
        "custom": createTheme({
            palette: {
                text: {
                    primary: settings.customPrimaryColor,
                    secondary: settings.customSecondaryColor,
                },
                primary: {
                    main: settings.customPaperColor
                },
                background: {
                    default: settings.customBackgroundColor
                }
            },
        }),
    };
}