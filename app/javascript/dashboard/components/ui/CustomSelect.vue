<template>
  <div ref="selectRef" class="custom-select" :class="{ 'custom-select--open': isOpen }">
    <button
      type="button"
      class="custom-select__trigger"
      :class="customClass"
      @click.stop="toggle"
      :disabled="disabled"
    >
      <span class="custom-select__value">{{ selectedLabel }}</span>
      <svg class="custom-select__arrow" viewBox="0 0 20 20" fill="currentColor">
        <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" />
      </svg>
    </button>
    
    <transition name="dropdown">
      <div v-if="isOpen" class="custom-select__dropdown" @click.stop>
        <div class="custom-select__options">
          <button
            v-for="option in options"
            :key="getOptionValue(option)"
            type="button"
            class="custom-select__option"
            :class="{ 'custom-select__option--selected': isSelected(option) }"
            @click.stop="selectOption(option)"
          >
            {{ getOptionLabel(option) }}
          </button>
        </div>
      </div>
    </transition>
  </div>
</template>

<script>
import { ref, computed, onMounted, onUnmounted } from 'vue';

export default {
  name: 'CustomSelect',
  props: {
    modelValue: {
      type: [String, Number],
      default: ''
    },
    options: {
      type: Array,
      required: true
    },
    disabled: {
      type: Boolean,
      default: false
    },
    customClass: {
      type: String,
      default: ''
    },
    valueKey: {
      type: String,
      default: 'value'
    },
    labelKey: {
      type: String,
      default: 'label'
    }
  },
  emits: ['update:modelValue', 'change'],
  setup(props, { emit }) {
    const isOpen = ref(false);
    const selectRef = ref(null);

    const selectedLabel = computed(() => {
      const selected = props.options.find(opt => getOptionValue(opt) === props.modelValue);
      return selected ? getOptionLabel(selected) : 'Selecione...';
    });

    const toggle = () => {
      if (!props.disabled) {
        isOpen.value = !isOpen.value;
      }
    };

    const close = () => {
      isOpen.value = false;
    };

    const selectOption = (option) => {
      const value = getOptionValue(option);
      emit('update:modelValue', value);
      emit('change', value);
      close();
    };

    const isSelected = (option) => {
      return getOptionValue(option) === props.modelValue;
    };

    const getOptionValue = (option) => {
      return typeof option === 'object' ? option[props.valueKey] : option;
    };

    const getOptionLabel = (option) => {
      return typeof option === 'object' ? option[props.labelKey] : option;
    };

    const handleClickOutside = (event) => {
      if (selectRef.value && !selectRef.value.contains(event.target) && isOpen.value) {
        close();
      }
    };

    onMounted(() => {
      // Adiciona listener com delay para evitar race condition
      setTimeout(() => {
        document.addEventListener('click', handleClickOutside);
      }, 100);
    });

    onUnmounted(() => {
      document.removeEventListener('click', handleClickOutside);
    });

    return {
      isOpen,
      selectRef,
      selectedLabel,
      toggle,
      close,
      selectOption,
      isSelected,
      getOptionValue,
      getOptionLabel
    };
  }
};
</script>

<style scoped lang="scss">
.custom-select {
  position: relative;
  width: 100%;

  &__trigger {
    display: flex;
    align-items: center;
    justify-content: space-between;
    width: 100%;
    padding: 8px 12px;
    border: 1px solid var(--s-200);
    border-radius: 6px;
    font-size: 13px;
    background: var(--white);
    color: var(--s-900);
    cursor: pointer;
    transition: all 0.15s;
    text-align: left;

    &:hover:not(:disabled) {
      border-color: var(--s-300);
    }

    &:focus {
      outline: none;
      border-color: var(--w-500);
    }

    &:disabled {
      opacity: 0.5;
      cursor: not-allowed;
    }
  }

  &__value {
    flex: 1;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  &__arrow {
    width: 16px;
    height: 16px;
    margin-left: 8px;
    flex-shrink: 0;
    transition: transform 0.2s;
    color: var(--s-500);
  }

  &--open &__arrow {
    transform: rotate(180deg);
  }

  &__dropdown {
    position: absolute;
    top: calc(100% + 4px);
    left: 0;
    right: 0;
    z-index: 1000;
    background: #ffffff;
    background-color: #ffffff;
    border: 1px solid var(--s-200);
    border-radius: 6px;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15), 0 0 0 1px rgba(0, 0, 0, 0.05);
    max-height: 240px;
    overflow-y: auto;

    &::-webkit-scrollbar {
      width: 6px;
    }

    &::-webkit-scrollbar-track {
      background: #f5f5f5;
      background-color: #f5f5f5;
    }

    &::-webkit-scrollbar-thumb {
      background: var(--s-300);
      background-color: var(--s-300);
      border-radius: 3px;

      &:hover {
        background: var(--s-400);
        background-color: var(--s-400);
      }
    }
  }

  &__options {
    padding: 4px;
    background: transparent;
  }

  &__option {
    display: block;
    width: 100%;
    padding: 8px 12px;
    border: none;
    background: transparent;
    color: var(--s-900);
    font-size: 13px;
    text-align: left;
    cursor: pointer;
    border-radius: 4px;
    transition: all 0.15s;

    &:hover {
      background: #f8f8f8;
      background-color: #f8f8f8;
    }

    &--selected {
      background: #e3f2fd;
      background-color: #e3f2fd;
      color: #1976d2;
      font-weight: 500;

      &:hover {
        background: #e3f2fd;
        background-color: #e3f2fd;
      }
    }
  }
}

.dropdown-enter-active,
.dropdown-leave-active {
  transition: all 0.2s ease;
}

.dropdown-enter-from,
.dropdown-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}

.dark {
  .custom-select {
    &__trigger {
      background: var(--s-900);
      border-color: var(--s-700);
      color: var(--s-200);

      &:hover:not(:disabled) {
        border-color: var(--s-600);
      }

      &:focus {
        border-color: var(--w-500);
      }
    }

    &__arrow {
      color: var(--s-400);
    }

    &__dropdown {
      background: #1e1e1e;
      background-color: #1e1e1e;
      border-color: var(--s-700);
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.6), 0 0 0 1px rgba(255, 255, 255, 0.1);
    }

    &__option {
      color: var(--s-200);

      &:hover {
        background: #2a2a2a;
        background-color: #2a2a2a;
      }

      &--selected {
        background: #1a4d8f;
        background-color: #1a4d8f;
        color: var(--w-200);

        &:hover {
          background: #1a4d8f;
          background-color: #1a4d8f;
        }
      }
    }
  }
}
</style>
