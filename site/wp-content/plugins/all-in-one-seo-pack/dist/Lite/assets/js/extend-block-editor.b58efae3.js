import{s,t as k,v as _}from"./app-core.3e3b5f4b.js";import{h as c}from"./utils.1419d5df.js";import{a as d}from"./icon.c5b6e5f1.js";import{_ as f}from"./vendor-other.ac1169a2.js";import"./vendor-vue-ui.65fbb3e9.js";import"./vendor-lodash.a7229f96.js";const{addFilter:h}=window.wp.hooks,{BlockControls:p}=window.wp.blockEditor,{Button:l,ToolbarGroup:$,ToolbarButton:x}=window.wp.components,{Fragment:b,render:y,unmountComponentAtNode:w}=window.wp.element,{createHigherOrderComponent:B}=window.wp.compose,{select:u,useSelect:A}=window.wp.data,I="all-in-one-seo-pack",m={generateWithAI:f("Generate with AI",I),editWithAI:f("Edit with AI",I)};let S=!1;const g=(a,n={})=>{window.aioseoBus.$emit("do-post-settings-main-tab-change",{name:"aiContent"}),a.classList.add("is-busy"),a.disabled=!0;const e=_(),t=s();setTimeout(()=>{t.initiator=n?.initiator,(!t.initiator||!t.initiator.slug)&&t.resetInitiator(),e.isModalOpened="image-generator",a.classList.remove("is-busy"),a.disabled=!1},500)},L=()=>{s().extend.imageBlockToolbar&&(S||(h("editor.BlockEdit","aioseo/extend-image-block-toolbar",B(n=>e=>{const t=e.name==="core/image"&&e.attributes?.url,r=A(o=>!t||!e.attributes?.id?null:o("core").getEntityRecord("postType","attachment",e.attributes.id)||null,[`media-${e.attributes.id}`]);return t?c`
				<${b}>
					<${p}>
						<${$}>
							<${x}
								icon=${d}
								iconSize=${24}
								label=${m.editWithAI}
								onClick=${o=>{g(o.currentTarget,{initiator:{slug:"image-block-toolbar",wpMedia:r}})}}
								style=${{maxHeight:"90%",alignSelf:"center",padding:"0"}}
							/>
						</${$}>
					</${p}>

					<${n} ...${e} />
				</${b}>`:c`<${n} ...${e} />`},"extendImageBlockToolbar")),S=!0))},N=()=>{if(!s().extend.imageBlockPlaceholder)return;const n=u("core/block-editor").getSelectedBlock();if(!n||n.name!=="core/image"||n.attributes?.url)return;const t=k().getElementById(`block-${n.clientId}`),r=t?.querySelector(".components-form-file-upload");if(!r||t?.querySelector(".aioseo-ai-image-generator-btn"))return;const o=document.createElement("div");y(c`
			<${l}
				className=${"aioseo-ai-image-generator-btn"}
				variant=${"secondary"}
				icon=${d}
				iconSize=${"20"}
				__next40pxDefaultSize=${!0}
			>
				${m.generateWithAI}
			</${l}>`,o);const i=o.firstChild?.cloneNode(!0);i&&(r.after(i),i.addEventListener("click",()=>{g(i,{initiator:{slug:"image-block-placeholder"}})})),w(o),o.remove()},W=()=>{if(!s().extend.featuredImageButton||u("core/edit-post").getActiveGeneralSidebarName()!=="edit-post/document")return;if(u("core/editor").getEditedPostAttribute("featured_media")){document.querySelector(".aioseo-ai-image-generator-btn-featured-image")?.remove();return}setTimeout(()=>{const e=document.querySelector(".editor-post-featured-image__container"),t=e?.querySelector("button");if(!t||e?.querySelector(".aioseo-ai-image-generator-btn-featured-image"))return;e.style.display="flex",e.style.gap="8px";const r=document.createElement("div");y(c`
				<${l}
					className=${"aioseo-ai-image-generator-btn-featured-image"}
					variant=${"secondary"}
					icon=${d}
					iconSize=${"20"}
					__next40pxDefaultSize=${!0}
					title=${m.generateWithAI}
				/>`,r);const o=r.firstChild?.cloneNode(!0);o&&(t.after(o),o.addEventListener("click",()=>{g(o,{initiator:{slug:"featured-image-btn"}})})),w(r),r.remove()})};export{W as extendFeaturedImageButton,N as extendImageBlockPlaceholder,L as extendImageBlockToolbar};
