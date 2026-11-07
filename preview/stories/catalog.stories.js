const css = "font:14px/1.5 'Segoe UI',system-ui,sans-serif;color:#171717;background:#f6f7f9;min-height:100vh;box-sizing:border-box;padding:24px";
function panel(html) { const root=document.createElement("div");root.style.cssText=css;root.innerHTML=html;return root; }
const button=(text,disabled=false)=>"<button "+(disabled?"disabled":"")+" style='font:inherit;background:"+(disabled?"#ddd":"#fff")+";padding:9px 13px;border:1px solid #aaa;border-radius:5px;margin:4px;color:#171717'>"+text+"</button>";
const shortcuts=[
["ВЕРХНИЙ РЕГИСТР","Ctrl + Alt + Shift + ↑"],
["нижний регистр","Ctrl + Alt + Shift + ↓"],
["Инвертировать","Ctrl + Alt + Shift + →"],
["Заголовки","Ctrl + Alt + Shift + ←"],
["Типографика","Ctrl + Alt + Shift + PgDn"],
["Типографика предложений","Ctrl + Alt + Shift + Delete"]
];
const rows=()=>shortcuts.map(([n,h])=>"<div style='display:flex;align-items:center;justify-content:space-between;padding:11px;border-bottom:1px solid #dedede;gap:18px'><span>"+n+"</span><kbd style='font:12px Consolas,monospace'>"+h+"</kbd></div>").join("");
const sheet=(content)=>"<p style='color:#666;font-size:12px'>HTML-спецификация нативного AutoHotkey UI; не исполняет приложение и не повторяет его пиксель-в-пиксель.</p><section style='max-width:750px;background:white;padding:20px;border:1px solid #ddd;border-radius:8px'>"+content+"</section>";
export default {title:"Awfulcases",parameters:{layout:"fullscreen"}};
export const Typography={render:()=>panel(sheet("<h1 style='font-size:24px'>Awful Cases</h1><p style='font-size:18px'>Настройки преобразования текста</p><p style='font-size:14px'>Выделите текст и примените горячую клавишу.</p><p style='font-size:12px;color:#666'>Подсказка · Segoe UI / системный шрифт Windows</p><code style='font-family:Consolas'>Ctrl + Alt + Shift + PgDn</code>"))};
Typography.storyName="Foundations / Typography";
export const Hotkeys={render:()=>panel(sheet("<h2>Горячие клавиши</h2>"+rows()))};
Hotkeys.storyName="Atoms / Key combinations";
export const ActionStates={render:()=>panel(sheet("<h2>Кнопки и состояния</h2>"+button("Сохранить")+button("Сбросить")+button("Недоступно",true)+"<p>Состояния: default, hover, focus, disabled; нативные эффекты Windows отличаются.</p>"))};
ActionStates.storyName="Atoms / Actions";
export const SettingRow={render:()=>panel(sheet("<h2>Группа настройки</h2><label><input type='checkbox' checked> Сохранять исходный буфер обмена</label><p>Переключатели показаны как концепция, не отражают точные имена реальных параметров.</p>"))};
SettingRow.storyName="Molecules / Setting row";
export const Dialog={render:()=>panel(sheet("<h2>Settings</h2><p>Редактирование сочетаний клавиш</p>"+rows()+"<footer style='margin-top:20px;text-align:right'>"+button("Save")+button("Cancel")+button("Reset")+"</footer>"))};
Dialog.storyName="Organisms / Settings dialog";
export const TrayMenu={render:()=>panel(sheet("<h2>Системный трей (структурный референс)</h2><ul><li>Settings</li><li>Reset to defaults</li><li>Exit</li></ul>"))};
TrayMenu.storyName="Screens / Tray menu";
export const Conflict={render:()=>panel(sheet("<h2>Состояние ошибки</h2><div style='padding:12px;background:#fff1f0;border:1px solid #dc2626'>Дублирующиеся горячие клавиши должны быть отклонены до сохранения.</div>"+button("Сохранить",true)))};
Conflict.storyName="Patterns / Shortcut conflict";
