(custom-set-variables
  ;; custom-set-variables was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 '(hscroll-margin 2)
 '(isearch-allow-scroll t)
 '(mouse-wheel-scroll-amount (quote (1 ((shift) . 5) ((control)))))
 '(show-paren-mode t)
 '(standard-indent 2)
 '(text-mode-hook (quote (turn-on-auto-fill text-mode-hook-identify))))
(custom-set-faces
  ;; custom-set-faces was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 '(default ((t (:inherit nil :stipple nil :background "white" :foreground "black" :inverse-video nil :box nil :strike-through nil :overline nil :underline nil :slant normal :weight normal :height 120 :width normal :foundry "unknown" :family "Ubuntu Mono")))))

;; Additions to Load Path
(add-to-list 'load-path "~/.emacs.d/")

;; whitespace stuff
(setq-default show-trailing-whitespace t)
(setq-default default-indicate-empty-lines t)

;; Delete selected text
(delete-selection-mode t)

;; Auto-Complete includes
(require 'auto-complete-config)
(add-to-list 'ac-dictionary-directories "~/.emacs.d/ac-dict")
(ac-config-default)
(ac-set-trigger-key "TAB")
(setq ac-auto-start nil)

